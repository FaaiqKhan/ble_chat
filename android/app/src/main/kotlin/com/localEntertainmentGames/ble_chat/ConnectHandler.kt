package com.localEntertainmentGames.ble_chat

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattConnectionSettings
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

@SuppressLint("MissingPermission")
class ConnectHandler(private val context: Context) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val EVENT_CHANNEL = "connect/events"
        const val METHOD_CHANNEL = "connect/methods"

        private const val CONNECTION_SETTINGS_SDK = 37
    }

    // GATT callbacks run on this thread, never on the main thread, so a slow callback
    // can't freeze the UI.
    private val gattThread = HandlerThread("ble-gatt").apply { start() }
    private val gattHandler = Handler(gattThread.looper)

    // Only used to get back onto the main thread when sending data to Dart.
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /** Sends to Dart. [EventChannel.EventSink] must be used on the main thread. */
    private fun emit(event: Map<String, Any?>) {
        scope.launch { eventSink?.success(event) }
    }

    private var eventSink: EventChannel.EventSink? = null
    private val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private var adapter = bluetoothManager.adapter
    private var bluetoothGatt: BluetoothGatt? = null

    private val bluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {

        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {

        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
            status: Int
        ) {

        }

        override fun onDescriptorRead(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
            value: ByteArray
        ) {

        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {

        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt?,
            descriptor: BluetoothGattDescriptor?,
            status: Int
        ) {

        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {

        }
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "connect" -> {
                result.success(null)
                connectToGATTServer(arguments = call.arguments)
            }

            "disconnect" -> {
                result.success(null)
                disconnectFromGATTServer()
            }

            "write" -> {}

            "setNotify" -> {}

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

    private fun connectToGATTServer(arguments: Any?) {
        val hostDeviceAddress = (arguments as String?) ?: run {
            eventSink?.error("invalid_argument", "Device address is required", null)
            return
        }
        val adapter = adapter ?: run {
            eventSink?.error("unavailable", "Bluetooth is not available", null)
            return
        }
        bluetoothGatt?.close()
        val hostDevice = adapter.getRemoteDevice(hostDeviceAddress)
        // autoConnect = false: connect now and fail fast. true means "connect whenever
        // the device shows up", which is slow and meant for reconnecting to a known
        // device. TRANSPORT_LE stops Android trying classic Bluetooth on dual-mode phones.
        @Suppress("DEPRECATION")
        bluetoothGatt = when {
            Build.VERSION.SDK_INT >= CONNECTION_SETTINGS_SDK -> {
                val settings = BluetoothGattConnectionSettings.Builder()
                    .setTransport(BluetoothDevice.TRANSPORT_LE)
                    .setAutoConnectEnabled(false)
                    .setAutomaticMtuEnabled(true)
                    .build()
                hostDevice.connectGatt(
                    settings,
                    { gattHandler.post(it) },
                    bluetoothGattCallback
                )
            }

            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> hostDevice.connectGatt(
                context,
                false,
                bluetoothGattCallback,
                BluetoothDevice.TRANSPORT_LE,
                BluetoothDevice.PHY_LE_1M_MASK,
                gattHandler
            )

            // minSdk is 24, so this is Android 7.x: no Handler overload, but its
            // callbacks already arrive on a Binder thread.
            else -> hostDevice.connectGatt(
                context,
                false,
                bluetoothGattCallback,
                BluetoothDevice.TRANSPORT_LE
            )
        }
    }

    private fun disconnectFromGATTServer() {
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
    }

    /** Stops everything. Call when the Flutter engine goes away. */
    fun release() {
        disconnectFromGATTServer()
        gattThread.quitSafely()
        scope.cancel()
    }
}