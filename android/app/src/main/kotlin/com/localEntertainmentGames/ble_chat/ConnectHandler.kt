package com.localEntertainmentGames.ble_chat

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattConnectionSettings
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothStatusCodes
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
import java.util.UUID
import java.util.concurrent.atomic.AtomicReference

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

    /** Reports a failure to Dart as a stream error. Main thread only, like [emit]. */
    private fun emitError(code: String, message: String) {
        scope.launch { eventSink?.error(code, message, null) }
    }

    private var eventSink: EventChannel.EventSink? = null

    // The write waiting for onCharacteristicWrite. GATT allows one at a time. Set on the
    // main thread, answered from the GATT thread, hence the atomic holder.
    private val pendingWrite = AtomicReference<MethodChannel.Result?>(null)

    /** Answers the waiting write, if any, on the main thread (Result requires it). */
    private fun finishWrite(error: Pair<String, String>?) {
        val result = pendingWrite.getAndSet(null) ?: return
        scope.launch {
            if (error == null) result.success(null) else result.error(
                error.first,
                error.second,
                null
            )
        }
    }

    private val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private var adapter = bluetoothManager.adapter

    // Written from the main thread (connect / disconnect) and the GATT thread (callbacks).
    @Volatile
    private var bluetoothGatt: BluetoothGatt? = null

    @Volatile
    private var bleCharacteristic: BluetoothGattCharacteristic? = null

    private val bluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            when (newState) {
                BluetoothGatt.STATE_CONNECTING -> {
                    emit(
                        mapOf(
                            "type" to "connection",
                            "status" to "connecting"
                        )
                    )
                }

                BluetoothGatt.STATE_CONNECTED -> {
                    emit(
                        mapOf(
                            "type" to "connection",
                            "status" to "connected"
                        )
                    )
                    // The `GATT` the callback gives: the field may still be null here,
                    // because this can run before connectGatt() returns and it is assigned.
                    gatt?.discoverServices()
                }

                BluetoothGatt.STATE_DISCONNECTING -> {
                    emit(
                        mapOf(
                            "type" to "connection",
                            "status" to "disconnecting"
                        )
                    )
                }

                BluetoothGatt.STATE_DISCONNECTED -> {
                    // A non-zero status means the connection failed or was dropped,
                    // not that we asked to disconnect (133 is the common generic failure).
                    if (status != BluetoothGatt.GATT_SUCCESS) {
                        emitError("connection_failed", "Connection failed (status $status)")
                    }
                    emit(
                        mapOf(
                            "type" to "connection",
                            "status" to "disconnected"
                        )
                    )
                    disconnectFromGATTServer()
                }

                else -> {}
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS || gatt == null) {
                emitError("service_discovery_failed", "Service discovery failed (status $status)")
                return
            }
            val characteristic = findGATTServerCharacteristics(
                gatt,
                Constants.SERVICE_UUID,
                Constants.CHARACTERISTIC_UUID
            )
            if (characteristic == null) {
                emitError("service_not_found", "This device is not hosting a room")
                return
            }
            bleCharacteristic = characteristic
            // Ready is reported from onDescriptorWrite, once notifications are on:
            // GATT runs one operation at a time, so a write sent before that fails.
            if (!setNotify(gatt, characteristic)) {
                emitError("notify_failed", "Could not enable notifications")
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {
            finishWrite(
                if (status == BluetoothGatt.GATT_SUCCESS) null
                else "write_failed" to "Write failed (status $status)"
            )
            // The host confirmed it got the message.
            if (status == BluetoothGatt.GATT_SUCCESS) {
                emit(
                    mapOf(
                        "type" to "message",
                        "status" to "sent"
                    )
                )
            }
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt?,
            descriptor: BluetoothGattDescriptor?,
            status: Int
        ) {
            if (descriptor?.uuid != Constants.CCCD_UUID) return
            if (status != BluetoothGatt.GATT_SUCCESS) {
                emitError(
                    "notify_failed",
                    "Could not enable notifications (status $status)"
                )
                return
            }
            // Connected, service found and notifications on: the room can be used.
            emit(
                mapOf(
                    "type" to "service",
                    "status" to "discovered"
                )
            )
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

            "write" -> writeToCharacteristic(call.arguments, result)

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
            eventSink?.error(
                "invalid_argument",
                "Device address is required",
                null
            )
            return
        }
        val adapter = adapter ?: run {
            eventSink?.error(
                "unavailable",
                "Bluetooth is not available",
                null
            )
            return
        }
        bluetoothGatt?.close()
        val hostDevice = try {
            adapter.getRemoteDevice(hostDeviceAddress)
        } catch (_: IllegalArgumentException) {
            eventSink?.error(
                "invalid_argument",
                "Not a valid device address",
                null
            )
            return
        }
        // autoConnect = false: connect now and fail fast. true means "connect whenever
        // the device shows up", which is slow and meant for reconnecting to a known
        // device. TRANSPORT_LE stops Android trying classic Bluetooth on dual-mode phones.
        @Suppress("DEPRECATION")
        val gatt = try {
            when {
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
        } catch (_: SecurityException) {
            eventSink?.error(
                "permission",
                "Bluetooth permission is missing",
                null
            )
            return
        }
        if (gatt == null) {
            eventSink?.error(
                "connect_failed",
                "Could not start the connection",
                null
            )
            return
        }
        bluetoothGatt = gatt
    }

    private fun disconnectFromGATTServer() {
        finishWrite("disconnected" to "Disconnected before the write finished")
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
        // It belonged to the connection that just ended.
        bleCharacteristic = null
    }

    /**
     * Writes [arguments] (bytes from Dart) to the room's characteristic. Dart doesn't
     * name the characteristic; the one found during service discovery is used. The
     * call is answered once the host confirms to write.
     */
    private fun writeToCharacteristic(arguments: Any?, result: MethodChannel.Result) {
        val data = arguments as? ByteArray ?: run {
            result.error(
                "invalid_argument",
                "Bytes to write are required",
                null
            )
            return
        }
        val gatt = bluetoothGatt
        val characteristic = bleCharacteristic
        if (gatt == null || characteristic == null) {
            result.error(
                "not_connected",
                "Not connected to a room",
                null
            )
            return
        }
        if (!pendingWrite.compareAndSet(null, result)) {
            result.error(
                "busy",
                "Another write is still in progress",
                null
            )
            return
        }

        val started = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                gatt.writeCharacteristic(
                    characteristic,
                    data,
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                ) == BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                run {
                    characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                    characteristic.value = data
                    gatt.writeCharacteristic(characteristic)
                }
            }
        } catch (_: SecurityException) {
            false
        }
        // The write never left the phone, so no callback will answer.
        if (!started) finishWrite("write_failed" to "Could not start the write")
    }

    /** Stops everything. Call when the Flutter engine goes away. */
    fun release() {
        disconnectFromGATTServer()
        gattThread.quitSafely()
        scope.cancel()
    }

    /** Find GATT server characteristics after creating a connection */
    private fun findGATTServerCharacteristics(
        gatt: BluetoothGatt,
        serviceUuid: UUID,
        characteristicUuid: UUID
    ): BluetoothGattCharacteristic? {
        return gatt.getService(serviceUuid)?.getCharacteristic(characteristicUuid)
    }

    /**
     * Turns on notifications from [characteristic]: tells this phone to deliver them, then
     * writes the host's CCCD descriptor so it sends them. Returns false if either step
     * could not start; otherwise the answer arrives in onDescriptorWrite.
     */
    @Suppress("DEPRECATION")
    private fun setNotify(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
    ): Boolean {
        if (!gatt.setCharacteristicNotification(characteristic, true)) return false
        val descriptor = characteristic.getDescriptor(Constants.CCCD_UUID) ?: return false
        val value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.writeDescriptor(descriptor, value) == BluetoothStatusCodes.SUCCESS
        } else {
            descriptor.value = value
            gatt.writeDescriptor(descriptor)
        }
    }
}
