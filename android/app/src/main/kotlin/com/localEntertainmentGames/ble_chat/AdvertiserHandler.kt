package com.localEntertainmentGames.ble_chat

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.milliseconds

/**
 * Turns the device into a BLE peripheral: it advertises a service and runs a GATT server
 * exposing one characteristic (read / write / notify) that central devices can connect to.
 *
 * Callers must hold BLUETOOTH_ADVERTISE and BLUETOOTH_CONNECT (Android 12+) before calling.
 */
@SuppressLint("MissingPermission")
class AdvertiserHandler(private val context: Context) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val EVENT_CHANNEL = "bleAdvertiser/events"
        const val METHOD_CHANNEL = "bleAdvertiser/methods"
        const val ADVERTISE_DURATION_MS = 60000
    }

    private var bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private val adapter get() = bluetoothManager?.adapter

    private var gattServer: BluetoothGattServer? = null
    private var characteristic: BluetoothGattCharacteristic? = null

    private val subscribers = mutableSetOf<BluetoothDevice>()
    private val connectedDevices = mutableSetOf<BluetoothDevice>()

    private var eventSink: EventChannel.EventSink? = null
    private var methodResult: MethodChannel.Result? = null

    private var advertising = false
    private var advertiser: BluetoothLeAdvertiser? = null
    private var pendingStart: MethodChannel.Result? = null

    private val mainCoroutineScope = MainScope()

    private fun emitConnectionError(type: String, message: String) {
        mainCoroutineScope.launch { eventSink?.error(type, message, null) }
    }

    private fun emitConnectionSuccess(type: String, state: String) {
        val event = mapOf<String, Any?>(
            "type" to type,
            "state" to state,
        )
        mainCoroutineScope.launch { eventSink?.success(event) }
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        methodResult = result
        when (call.method) {
            "start" -> {
                // Progress and failures are reported on the event channel, so the call
                // itself only acknowledges that the request was received.
                result.success(null)
                start(call.arguments as String)
            }

            "stop" -> {
                // Completion is reported with the "roomClosed" event.
                result.success(null)
                try {
                    stop()
                } catch (e: Exception) {
                    emitConnectionError("close_room", e.message ?: "Unable to close the room")
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // stopAdvertising must receive the same callback instance that started the advertisement.
    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            advertising = true
            emitConnectionSuccess("progress", "advertisingStarted")
//            mainCoroutineScope.launch {
//                pendingStart?.success(null)
//                pendingStart = null
//            }
        }

        override fun onStartFailure(errorCode: Int) {
            advertising = false
            emitConnectionError("advertise_failed", "Advertising failed (code $errorCode)")
//            stop(true)
//            mainCoroutineScope.launch {
//                pendingStart?.error("advertise_failed", errorMessage(errorCode), errorCode)
//                pendingStart = null
//            }
        }
    }

    private fun start(name: String) {
        val adapter = adapter
        if (adapter == null || !adapter.isEnabled) {
            emitConnectionError("bluetooth", "Bluetooth is not ready")
            return
        }
        val advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            emitConnectionError(
                "advertisingUnsupported",
                "This device does not support BLE advertising"
            )
            return
        }
        if (advertising) return

        // Bluetooth is enabled and all the required objects are available notify the dart
        // about having it
        emitConnectionSuccess("progress", "bluetoothReady")

        openGattServer()

        // The device name goes in the scan response so the 31-byte advertising packet
        // only has to hold the flags and the 128-bit service UUID.
        adapter.name = name

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .setTimeout(ADVERTISE_DURATION_MS)
            .build()
        val advertiseData = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(Constants.SERVICE_UUID))
            .build()
        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .build()

        this.advertiser = advertiser
        advertiser.startAdvertising(settings, advertiseData, scanResponse, advertiseCallback)
    }

    fun stop() {
        advertiser?.stopAdvertising(advertiseCallback)
        advertiser = null
        advertising = false
        closeGattServer()
    }

    private val bluetoothGattServerCallback = object : BluetoothGattServerCallback() {
        override fun onServiceAdded(status: Int, service: BluetoothGattService?) {
            emitConnectionSuccess("progress", "serviceCreated")
        }

        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic?
        ) {
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            descriptor: BluetoothGattDescriptor?
        ) {

        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            descriptor: BluetoothGattDescriptor?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
        }
    }

    private fun openGattServer() {
        if (gattServer != null) return
        if (bluetoothManager == null) {
            eventSink?.error("create_room_service", "Unable to create room service", null)
            return
        }

        val server = bluetoothManager.openGattServer(context, bluetoothGattServerCallback)

        val characteristic = BluetoothGattCharacteristic(
            Constants.CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or
                    BluetoothGattCharacteristic.PROPERTY_WRITE or
                    BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ or
                    BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        // Descriptor that lets centrals subscribe to notifications.
        characteristic.addDescriptor(
            BluetoothGattDescriptor(
                Constants.CCCD_UUID,
                BluetoothGattDescriptor.PERMISSION_READ or
                        BluetoothGattDescriptor.PERMISSION_WRITE,
            )
        )
        val service = BluetoothGattService(
            Constants.SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )
        service.addCharacteristic(characteristic)
        server.addService(service)

        this.characteristic = characteristic
        gattServer = server
    }

    private fun closeGattServer() {
        // Closing the server drops every central without a callback, so report it ourselves.
        val dropped = connectedDevices.toList()
        connectedDevices.clear()
//        dropped.forEach { emitConnection(it, "disconnected", BluetoothGatt.GATT_SUCCESS) }
        emitConnectionSuccess("roomClosed", "success")
        subscribers.clear()
        gattServer?.close()
        gattServer = null
        characteristic = null
    }
}