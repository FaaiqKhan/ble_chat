package com.localEntertainmentGames.ble_chat

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Build
import android.os.SystemClock
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
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
        const val ADVERTISE_DURATION_MS = 60_000L
        private const val DEFAULT_MTU = 23

        // A connected guest has this long to send the right code, and this many tries.
        private const val AUTH_TIMEOUT_MS = 10_000L
        private const val MAX_AUTH_ATTEMPTS = 3

        // Connections allowed on top of the authenticated guests, so a stranger can't
        // fill every slot. Each lasts at most AUTH_TIMEOUT_MS.
        private const val PENDING_SLOTS = 2
    }

    private var bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private val adapter get() = bluetoothManager?.adapter

    private var gattServer: BluetoothGattServer? = null
    private var characteristic: BluetoothGattCharacteristic? = null

    // Changed from GATT server callbacks (Binder threads), hence concurrent sets.
    private val subscribers: MutableSet<BluetoothDevice> = ConcurrentHashMap.newKeySet()
    private val connectedDevices: MutableSet<BluetoothDevice> = ConcurrentHashMap.newKeySet()

    // Each guest's negotiated MTU. A notification can carry at most mtu - 3 bytes.
    private val deviceMtu = ConcurrentHashMap<BluetoothDevice, Int>()

    private var eventSink: EventChannel.EventSink? = null
    private var methodResult: MethodChannel.Result? = null

    private var advertising = false
    private var advertiser: BluetoothLeAdvertiser? = null

    // When the room stops being visible (elapsedRealtime). Set when advertising first
    // succeeds and kept across the restarts that refresh the people count.
    @Volatile
    private var advertiseEndsAt = 0L

    // The room being advertised, kept so the people count can be refreshed later.
    private var room: Utils.RoomAd? = null

    private val mainCoroutineScope = MainScope()
    private var autoStopJob: Job? = null
    private var authCode: String? = null

    // Addresses of the guests that sent the right code. Only these may chat or subscribe.
    private val authenticated: MutableSet<String> = ConcurrentHashMap.newKeySet()
    private val failedAttempts = ConcurrentHashMap<String, Int>()
    private val authTimeouts = ConcurrentHashMap<String, Job>()

    private fun emitConnectionError(type: String, message: String) {
        mainCoroutineScope.launch { eventSink?.error(type, message, null) }
    }

    private fun emitConnectionSuccess(type: String, state: String, authCode: String? = null) {
        val event = mapOf<String, Any?>(
            "type" to type,
            "state" to state,
            "authCode" to authCode,
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
                val details = Utils.getRoomDetails(call.arguments())
                if (details == null) {
                    eventSink?.error(
                        "invalid_format",
                        "Argument must be a Map with roomName and roomCode",
                        null
                    )
                    return
                }
                start(details)
            }

            "updatePeople" -> {
                result.success(null)
                updatePeople(call.arguments as? Int ?: return)
            }

            "send" -> sendToGuests(call.arguments, result)

            "stop" -> {
                // Completion is reported with the "roomClosed" event.
                result.success(null)
                try {
                    stop(true)
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

    /**
     * Stops everything: advertising, the GATT server and its connected guests, and the
     * timers. Call when the Flutter engine goes away; the handler can't be used after.
     */
    fun release() {
        eventSink = null
        stop(true)
        mainCoroutineScope.cancel()
    }

    // stopAdvertising must receive the same callback instance that started the advertisement.
    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            advertising = true
            // A refresh (new people count) restarts advertising but must not extend the
            // time the room stays visible, so the timer only starts once.
            if (autoStopJob == null) {
                advertiseEndsAt = SystemClock.elapsedRealtime() + ADVERTISE_DURATION_MS
                autoStopJob = mainCoroutineScope.launch {
                    delay(ADVERTISE_DURATION_MS.milliseconds)
                    stop(false)
                }
            }
            emitConnectionSuccess("progress", "advertisingStarted", authCode)
        }

        override fun onStartFailure(errorCode: Int) {
            advertising = false
            emitConnectionError("advertise_failed", "Advertising failed (code $errorCode)")
            stop(true)
        }
    }

    private fun start(details: Utils.RoomAd) {
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

        // The 6-digit code guests need to join. Made once per room (and shown to the host
        // with the first progress event); it is never advertised.
        if (authCode == null) authCode = Utils.generateAuthCode()

        // The room identity travels in the advertising packet itself as manufacturer data,
        // so a scanner can filter on it in hardware (a scan response can't be filtered
        // on). The service id is left out of the packet to make room; guests find the
        // GATT service after connecting. The identity is not put in the Bluetooth device
        // name: renaming the adapter is asynchronous and would rename the user's phone.
        room = details
        val advertiseData = buildAdvertiseData(details) ?: return

        val settings = advertiseSettings(ADVERTISE_DURATION_MS, details.people < details.maxPeople)

        this.advertiser = advertiser
        advertiser.startAdvertising(settings, advertiseData, advertiseCallback)
    }

    /**
     * [timeoutMs] is the system's own stop time (it allows 0 to 180000). The coroutine
     * timer in this class does the same job and reports it, but it can't run if Android
     * freezes the app in the background; the Bluetooth controller still stops on time.
     */
    private fun advertiseSettings(timeoutMs: Long, connectable: Boolean) =
        AdvertiseSettings.Builder()
        .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
        .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
        // A full room is still advertised (scanners show it as FULL) but can't be connected to.
        .setConnectable(connectable)
        .setTimeout(timeoutMs.toInt())
        .build()

    /** Null (after reporting the error) if the room can't be encoded into the packet. */
    private fun buildAdvertiseData(details: Utils.RoomAd): AdvertiseData? {
        val payload = Utils.encodeAdvertisement(details)
        if (payload == null) {
            emitConnectionError(
                "advertise_failed",
                "Room name is too long to advertise (16 characters at most)"
            )
            return null
        }
        return AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addManufacturerData(Constants.MANUFACTURER_ID, payload)
            .build()
    }

    /**
     * Tells scanners how many people are in the room. Advertising data can't be changed
     * in place, so advertising is restarted with the new count. Does nothing while the
     * room isn't being advertised; the count is picked up if it starts again.
     */
    private fun updatePeople(people: Int) {
        val current = room ?: return
        if (current.people == people) return
        val updated = current.copy(people = people)
        room = updated
        val advertiser = advertiser
        if (!advertising || advertiser == null) return

        // Restarting must not give the room a fresh timeout: only what is left of the
        // original one. Nothing left means it is about to stop anyway.
        val remaining = advertiseEndsAt - SystemClock.elapsedRealtime()
        if (remaining <= 0) return

        val data = buildAdvertiseData(updated) ?: return
        advertiser.stopAdvertising(advertiseCallback)
        advertiser.startAdvertising(
            advertiseSettings(remaining, updated.people < updated.maxPeople),
            data,
            advertiseCallback
        )
    }

    fun stop(closeServer: Boolean) {
        autoStopJob?.cancel()
        autoStopJob = null
        advertiser?.stopAdvertising(advertiseCallback)
        advertiser = null
        advertising = false
        if (closeServer) {
            // The code belongs to the room, not to advertising: it stays valid when
            // advertising merely times out, and goes when the room closes.
            authCode = null
            room = null
            closeGattServer()
        }
    }

    private val bluetoothGattServerCallback = object : BluetoothGattServerCallback() {
        override fun onServiceAdded(status: Int, service: BluetoothGattService?) {
            emitConnectionSuccess("progress", "serviceCreated")
        }

        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
            device ?: return
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> onGuestConnected(device)
                BluetoothProfile.STATE_DISCONNECTED -> forgetGuest(device)
            }
        }

        override fun onMtuChanged(device: BluetoothDevice?, mtu: Int) {
            if (device != null) deviceMtu[device] = mtu
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
            if (device == null) return

            if (characteristic?.uuid == Constants.AUTH_CHARACTERISTIC_UUID) {
                handleAuthWrite(device, requestId, responseNeeded, offset, value)
                return
            }

            // Everything below is only for guests that sent the right code.
            if (device.address !in authenticated) {
                respond(
                    device, requestId, responseNeeded,
                    BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION, offset, value
                )
                return
            }

            val message = Utils.decodeMessage(value)
            val isRoomWrite = characteristic?.uuid == Constants.CHARACTERISTIC_UUID
            // Without this answer the guest's write never completes and, after about 30
            // seconds, the connection is dropped.
            respond(
                device, requestId, responseNeeded,
                if (isRoomWrite && message != null) BluetoothGatt.GATT_SUCCESS
                else BluetoothGatt.GATT_FAILURE,
                offset, value
            )
            if (!isRoomWrite || message == null || value == null) return

            // Guests don't talk to each other: the host passes the message on, unchanged,
            // to everyone else subscribed, and tells its own Dart side.
            notifySubscribers(value, except = device)
            emitEvent(
                mapOf(
                    "type" to "message",
                    "id" to message.id,
                    "sender" to message.sender,
                    "data" to message.text,
                )
            )
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            descriptor: BluetoothGattDescriptor?
        ) {
            if (device == null) return
            // Only the CCCD is read: whether this guest has notifications on.
            if (descriptor?.uuid == Constants.CCCD_UUID) {
                val value = if (device in subscribers) {
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                } else {
                    BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                }
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, value)
            } else {
                gattServer?.sendResponse(
                    device, requestId, BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED, 0, null
                )
            }
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
            if (device == null) return
            // Subscribing is how a guest receives messages, so it needs the code first.
            if (device.address !in authenticated) {
                respond(
                    device, requestId, responseNeeded,
                    BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION, offset, value
                )
                return
            }
            var status = BluetoothGatt.GATT_SUCCESS
            if (descriptor?.uuid == Constants.CCCD_UUID) {
                // The guest switching notifications on or off for this characteristic.
                when {
                    value contentEquals BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE ->
                        subscribers.add(device)

                    value contentEquals BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE ->
                        subscribers.remove(device)

                    else -> status = BluetoothGatt.GATT_FAILURE
                }
            } else {
                status = BluetoothGatt.GATT_FAILURE
            }
            respond(device, requestId, responseNeeded, status, offset, value)
        }
    }

    /** Answers a GATT request; guests wait for this (see the 30 second note above). */
    private fun respond(
        device: BluetoothDevice,
        requestId: Int,
        responseNeeded: Boolean,
        status: Int,
        offset: Int,
        value: ByteArray?
    ) {
        if (responseNeeded) gattServer?.sendResponse(device, requestId, status, offset, value)
    }

    /**
     * A new connection. Not trusted yet: it may only exist for a few seconds unless it
     * sends the right code. Refused outright if the room is full or too many unproven
     * connections are already open.
     */
    private fun onGuestConnected(device: BluetoothDevice) {
        val guestSpots = (room?.maxPeople ?: 0) - 1
        val pending = connectedDevices.count { it.address !in authenticated }
        if (authenticated.size >= guestSpots || pending >= PENDING_SLOTS) {
            gattServer?.cancelConnection(device)
            return
        }
        connectedDevices.add(device)
        authTimeouts[device.address] = mainCoroutineScope.launch {
            delay(AUTH_TIMEOUT_MS.milliseconds)
            if (device.address !in authenticated) gattServer?.cancelConnection(device)
        }
    }

    /** A guest is gone (left, dropped, or was refused): forget everything about it. */
    private fun forgetGuest(device: BluetoothDevice) {
        connectedDevices.remove(device)
        deviceMtu.remove(device)
        subscribers.remove(device)
        failedAttempts.remove(device.address)
        authTimeouts.remove(device.address)?.cancel()
        if (authenticated.remove(device.address)) onGuestsChanged("left", device)
    }

    /**
     * A guest wrote the join code. A right code lets it chat; a wrong one is answered with
     * GATT_INSUFFICIENT_AUTHENTICATION, which the guest reports as "wrong code". After
     * MAX_AUTH_ATTEMPTS wrong codes the connection is cut.
     */
    private fun handleAuthWrite(
        device: BluetoothDevice,
        requestId: Int,
        responseNeeded: Boolean,
        offset: Int,
        value: ByteArray?
    ) {
        val expected = authCode?.toByteArray(Charsets.UTF_8)
        // isEqual takes the same time however many digits match.
        val correct = expected != null && value != null && MessageDigest.isEqual(expected, value)
        val address = device.address

        if (correct) {
            failedAttempts.remove(address)
            authTimeouts.remove(address)?.cancel()
            respond(device, requestId, responseNeeded, BluetoothGatt.GATT_SUCCESS, offset, value)
            if (authenticated.add(address)) onGuestsChanged("joined", device)
            return
        }

        val attempts = failedAttempts.merge(address, 1, Int::plus) ?: 1
        respond(
            device, requestId, responseNeeded,
            BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION, offset, value
        )
        if (attempts >= MAX_AUTH_ATTEMPTS) gattServer?.cancelConnection(device)
    }

    /** The set of authenticated guests changed: refresh the advertised count, tell Dart. */
    private fun onGuestsChanged(state: String, device: BluetoothDevice) {
        val people = authenticated.size + 1
        updatePeople(people)
        emitEvent(
            mapOf(
                "type" to "peer",
                "state" to state,
                "address" to device.address,
                "people" to people,
            )
        )
    }

    /**
     * Sends a message from the host to every subscribed guest. [arguments] is a map:
     * `sender` (the name to show, at most 20 bytes) and `text` (the message bytes).
     * Answers with the random message id. Notifications aren't confirmed by guests, so
     * success means it was handed to the Bluetooth stack for each subscriber.
     */
    private fun sendToGuests(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<*, *>
        val sender = args?.get("sender") as? String
        val text = args?.get("text") as? ByteArray
        if (sender == null || text == null) {
            result.error("invalid_argument", "A sender name and the text bytes are required", null)
            return
        }
        if (gattServer == null || characteristic == null) {
            result.error("not_hosting", "The room is not open", null)
            return
        }
        val id = Utils.newMessageId()
        val payload = Utils.encodeMessage(Utils.ChatMessage(id, sender, text)) ?: run {
            result.error("invalid_argument", "The sender name is too long", null)
            return
        }
        // The smallest guest limit decides, so every guest gets the same message.
        val limit = (subscribers.minOfOrNull { deviceMtu[it] ?: DEFAULT_MTU } ?: DEFAULT_MTU) - 3
        if (payload.size > limit) {
            result.error(
                "message_too_long",
                "A message can be at most ${limit - payload.size + text.size} bytes",
                null
            )
            return
        }
        notifySubscribers(payload, except = null)
        result.success(id)
    }

    /** Sends [value] to every subscribed guest except [except] (the one it came from). */
    @Suppress("DEPRECATION")
    private fun notifySubscribers(value: ByteArray, except: BluetoothDevice?) {
        val server = gattServer ?: return
        val characteristic = characteristic ?: return
        for (guest in subscribers) {
            if (guest == except) continue
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                server.notifyCharacteristicChanged(guest, characteristic, false, value)
            } else {
                characteristic.value = value
                server.notifyCharacteristicChanged(guest, characteristic, false)
            }
        }
    }

    private fun emitEvent(event: Map<String, Any?>) {
        mainCoroutineScope.launch { eventSink?.success(event) }
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
            BluetoothGattCharacteristic.PROPERTY_WRITE or
                    BluetoothGattCharacteristic.PROPERTY_NOTIFY,
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
        // Where a guest writes the join code. A characteristic of its own (not a
        // descriptor), so the host knows what a write means from where it lands.
        val authCharacteristic = BluetoothGattCharacteristic(
            Constants.AUTH_CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        val service = BluetoothGattService(
            Constants.SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )
        service.addCharacteristic(characteristic)
        service.addCharacteristic(authCharacteristic)
        server.addService(service)

        this.characteristic = characteristic
        gattServer = server
    }

    private fun closeGattServer() {
        // Closing the server drops every central without a callback, so report it ourselves.
//        val dropped = connectedDevices.toList()
        connectedDevices.clear()
//        dropped.forEach { emitConnection(it, "disconnected", BluetoothGatt.GATT_SUCCESS) }
        emitConnectionSuccess("roomClosed", "success")
        subscribers.clear()
        authenticated.clear()
        failedAttempts.clear()
        authTimeouts.values.forEach { it.cancel() }
        authTimeouts.clear()
        deviceMtu.clear()
        gattServer?.close()
        gattServer = null
        characteristic = null
    }
}