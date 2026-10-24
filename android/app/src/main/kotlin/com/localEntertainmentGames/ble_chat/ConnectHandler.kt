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
        private const val REQUESTED_MTU = 247

        // How often the signal strength of the link to the host is read once joined.
        private const val RSSI_INTERVAL_MS = 2_000L
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

    /** Progress for Dart's step list: [step] (connect, discover, authenticate, join) is done. */
    private fun emitStep(step: String) = emit(mapOf("type" to "progress", "step" to step))

    /** A failure that ends the attempt: tell Dart, then drop the connection. */
    private fun fail(code: String, message: String) {
        emitError(code, message)
        disconnectFromGATTServer()
    }

    // Reads the link's signal strength every RSSI_INTERVAL_MS while connected (also during
    // the joining steps); the answer arrives in onReadRemoteRssi. Runs on the GATT thread.
    // Reading the signal doesn't use the GATT request queue, so it can't collide with
    // discovery or the code write.
    private val rssiPoll = object : Runnable {
        override fun run() {
            val gatt = bluetoothGatt ?: return
            try {
                gatt.readRemoteRssi()
            } catch (_: SecurityException) {
                return
            }
            gattHandler.postDelayed(this, RSSI_INTERVAL_MS)
        }
    }

    private var eventSink: EventChannel.EventSink? = null

    // The write waiting for onCharacteristicWrite. GATT allows one at a time. Set on the
    // main thread, answered from the GATT thread, hence the atomic holder.
    private val pendingWrite = AtomicReference<MethodChannel.Result?>(null)

    // Id of the message that write is carrying; sent back when the host confirms it.
    private val pendingMessageId = AtomicReference<String?>(null)

    // Largest write is mtu - 3 bytes (3 are the protocol's own). 23 until negotiated.
    @Volatile
    private var mtu = 23

    /** Answers the waiting write, if any, on the main thread (Result requires it). */
    private fun finishWrite(error: Pair<String, String>?, value: Any? = null) {
        val result = pendingWrite.getAndSet(null) ?: return
        scope.launch {
            if (error == null) result.success(value) else result.error(
                error.first,
                error.second,
                null
            )
        }
    }

    private val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private var adapter = bluetoothManager.adapter
    // The join code for the connection being made. Used once, right after discovery.
    private var authCode: String? = null

    // The chat characteristic found at discovery. It only becomes bleCharacteristic (the
    // one messages are sent to) once the host accepted the code and notifications are on.
    @Volatile
    private var discoveredChat: BluetoothGattCharacteristic? = null

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
                    emitStep("connect")
                    // Linked: keep the signal bars live from now on, while the rest of
                    // the joining steps run and after. connectGatt() may not have returned
                    // yet (so the field can still be null); it is the same object.
                    if (bluetoothGatt == null) bluetoothGatt = gatt
                    gattHandler.removeCallbacks(rssiPoll)
                    gattHandler.post(rssiPoll)

                    // The `GATT` the callback gives: the field may still be null here,
                    // because this can run before connectGatt() returns and it is assigned.
                    // Before Android 17 the MTU isn't raised automatically; ask for a bigger
                    // one first and discover services once it is answered (onMtuChanged).
                    if (Build.VERSION.SDK_INT >= CONNECTION_SETTINGS_SDK ||
                        gatt?.requestMtu(REQUESTED_MTU) != true
                    ) {
                        gatt?.discoverServices()
                    }
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

        override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) this@ConnectHandler.mtu = mtu
            // Android 17 negotiates the MTU itself and discovers services right away.
            if (Build.VERSION.SDK_INT < CONNECTION_SETTINGS_SDK) gatt?.discoverServices()
        }

        override fun onReadRemoteRssi(gatt: BluetoothGatt?, rssi: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                emit(mapOf("type" to "rssi", "rssi" to rssi))
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS || gatt == null) {
                fail("service_discovery_failed", "Service discovery failed (status $status)")
                return
            }
            val chat = findGATTServerCharacteristics(
                gatt,
                Constants.SERVICE_UUID,
                Constants.CHARACTERISTIC_UUID
            )
            val auth = findGATTServerCharacteristics(
                gatt,
                Constants.SERVICE_UUID,
                Constants.AUTH_CHARACTERISTIC_UUID
            )
            if (chat == null || auth == null) {
                fail("service_not_found", "This device is not hosting a room")
                return
            }
            emitStep("discover")

            // The host only lets a guest chat after it has received the join code, so the
            // code goes first. Notifications are turned on once the host accepts it.
            discoveredChat = chat
            val code = authCode
            authCode = null
            if (code == null || !writeValue(gatt, auth, code.toByteArray(Charsets.UTF_8))) {
                fail("auth_failed", "Could not send the join code")
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {
            if (characteristic?.uuid == Constants.AUTH_CHARACTERISTIC_UUID) {
                onAuthResult(gatt, status)
                return
            }
            val id = pendingMessageId.getAndSet(null)
            finishWrite(
                if (status == BluetoothGatt.GATT_SUCCESS) null
                else "write_failed" to "Write failed (status $status)",
                value = id
            )
            // The host confirmed it got the message.
            if (status == BluetoothGatt.GATT_SUCCESS) {
                emit(
                    mapOf(
                        "type" to "message",
                        "status" to "sent",
                        "id" to id
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
                fail("notify_failed", "Could not enable notifications (status $status)")
                return
            }
            // Connected, code accepted and notifications on: messages can now be sent.
            bleCharacteristic = discoveredChat
            emitStep("join")
        }

        // Android 13+ calls this one.
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            emitReceived(value)
        }

        // Android 12 and older never call the method above; the value is on the
        // characteristic. (Android 13+ doesn't call this one when the above is overridden.)
        @Deprecated("Used for Android 12 and older")
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?
        ) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return
            // Copied: the same characteristic object is reused by the next notification.
            characteristic?.value?.copyOf()?.let(::emitReceived)
        }
    }

    /**
     * The host answered the join code. Accepted: turn on notifications (the answer comes
     * in onDescriptorWrite). Refused with INSUFFICIENT_AUTHENTICATION: the code was wrong.
     */
    private fun onAuthResult(gatt: BluetoothGatt?, status: Int) {
        if (status != BluetoothGatt.GATT_SUCCESS) {
            if (status == BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION) {
                fail("wrong_code", "That code didn't match")
            } else {
                fail("auth_failed", "The host could not check the code (status $status)")
            }
            return
        }
        emitStep("authenticate")
        val chat = discoveredChat
        if (gatt == null || chat == null || !setNotify(gatt, chat)) {
            fail("notify_failed", "Could not enable notifications")
        }
    }

    /** Hands a message relayed by the host to Dart: who sent it, its id, and the text bytes. */
    private fun emitReceived(value: ByteArray) {
        val message = Utils.decodeMessage(value) ?: return
        emit(
            mapOf(
                "type" to "message",
                "status" to "received",
                "id" to message.id,
                "sender" to message.sender,
                "data" to message.text
            )
        )
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

            "send" -> writeToCharacteristic(call.arguments, result)

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
        val hostDeviceDetails = (arguments as? Map<*, *>) ?: run {
            eventSink?.error(
                "invalid_argument",
                "Device address and auth code is required",
                null
            )
            return
        }
        val address: String = (hostDeviceDetails["address"] as String?) ?: run {
            eventSink?.error(
                "missing_address",
                "Device address is required",
                null,
            )
            return
        }
        val authCode: String = (hostDeviceDetails["authCode"] as String?) ?: run {
            eventSink?.error(
                "missing_auth",
                "Authentication code is required",
                null,
            )
            return
        }
        this.authCode = authCode
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
            adapter.getRemoteDevice(address)
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
        gattHandler.removeCallbacks(rssiPoll)
        finishWrite("disconnected" to "Disconnected before the write finished")
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
        // They belonged to the connection that just ended.
        bleCharacteristic = null
        discoveredChat = null
        pendingMessageId.set(null)
        authCode = null
        mtu = 23
    }

    /**
     * Sends a chat message. [arguments] is a map: `sender` (the name to show, at most 20
     * bytes) and `text` (the message bytes). Dart doesn't name the characteristic; the
     * one found during service discovery is used. A random message id is generated here.
     * The call is answered with that id once the host confirms the write.
     */
    private fun writeToCharacteristic(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<*, *>
        val sender = args?.get("sender") as? String
        val text = args?.get("text") as? ByteArray
        if (sender == null || text == null) {
            result.error(
                "invalid_argument",
                "A sender name and the text bytes are required",
                null
            )
            return
        }
        // The id is made here, so Dart gets it back when the host confirms the message.
        val messageId = Utils.newMessageId()
        val data = Utils.encodeMessage(Utils.ChatMessage(messageId, sender, text)) ?: run {
            result.error("invalid_argument", "The sender name is too long", null)
            return
        }
        if (data.size > mtu - 3) {
            result.error(
                "message_too_long",
                "A message can be at most ${mtu - 3 - data.size + text.size} bytes",
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
        pendingMessageId.set(messageId)

        val started = writeValue(gatt, characteristic, data)
        // The write never left the phone, so no callback will answer.
        if (!started) {
            pendingMessageId.set(null)
            finishWrite("write_failed" to "Could not start the write")
        }
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

    /** Starts writing [data] to [characteristic] (with response). False if it could not start. */
    private fun writeValue(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        data: ByteArray
    ): Boolean = try {
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
}
