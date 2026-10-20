package com.localEntertainmentGames.ble_chat

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration.Companion.milliseconds

/**
 * Looks for rooms advertised by [AdvertiserHandler].
 *
 * Messages sent on the event channel (Dart parses them in `ScannerEvent`):
 *  - `scan_started`: the radio is scanning
 *  - `scan_result`: a room with a matching name was seen; sent once per host, as hosts
 *    are found, because several rooms can share a name
 *  - `scan_timeout`: the scan time is over (Dart knows from its own list if anything matched)
 *  - errors (`EventSink.error`): `bluetooth`, `scan_failed`
 */
@SuppressLint("MissingPermission")
class ScannerHandler(context: Context) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val EVENT_CHANNEL = "bleScanner/events"
        const val METHOD_CHANNEL = "bleScanner/methods"
        private const val SCANNING_DURATION_MS = 10_000L
    }

    private val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private val adapter get() = bluetoothManager?.adapter
    private var eventSink: EventChannel.EventSink? = null
    private var autoStopScanning: Job? = null
    private val mainCoroutineScope: CoroutineScope = MainScope()

    // Scan callbacks arrive on a Binder thread, so these are read across threads.
    private val isScanning = AtomicBoolean(false)

    // Hosts already reported in this scan; the same host advertises many times a second.
    private val reportedAddresses: MutableSet<String> = ConcurrentHashMap.newKeySet()

    @Volatile
    private var query: String = ""

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "scan" -> {
                val search = (call.arguments as? String)?.trim()
                if (search.isNullOrEmpty()) {
                    // A bad request is answered on the call itself.
                    result.error("invalid_argument", "A room name or code is required", null)
                    return
                }
                // Reply once, here. Progress and failures travel on the event channel.
                result.success(null)
                startScanning(search)
            }

            "stop" -> {
                result.success(null)
                stopScanning()
            }

            else -> result.notImplemented()
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            val record = result?.scanRecord ?: return
            val identity = record.deviceName ?: return
            // The host advertises "RoomName · CODE". Only the name is searched, so a
            // code can't make a different room match.
            val roomName = identity.substringBeforeLast(Utils.IDENTITY_SEPARATOR)
            if (!roomName.contains(query, ignoreCase = true)) return
            if (!reportedAddresses.add(result.device.address)) return

            val event = mapOf(
                "type" to "scan_result",
                "address" to result.device.address,
                "name" to identity,
                "rssi" to result.rssi,
            )
            mainCoroutineScope.launch { eventSink?.success(event) }
        }

        override fun onScanFailed(errorCode: Int) {
            mainCoroutineScope.launch {
                stopScanning()
                eventSink?.error("scan_failed", "Scan failed with code $errorCode", errorCode)
            }
        }
    }

    private fun startScanning(search: String) {
        // One scan at a time; the running one keeps reporting to the same listener.
        if (!isScanning.compareAndSet(false, true)) return

        val scanner = adapter?.takeIf { it.isEnabled }?.bluetoothLeScanner
        if (scanner == null) {
            isScanning.set(false)
            eventSink?.error("bluetooth", "Bluetooth is not available", null)
            return
        }

        query = search
        reportedAddresses.clear()

        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        // Filter on the service id, which sits in the advertising packet itself.
        // The room name lives in the scan response, which hardware name filters
        // don't reliably look at, so the name is compared in onScanResult.
        val scanFilters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(Constants.SERVICE_UUID))
                .build()
        )
        scanner.startScan(scanFilters, scanSettings, scanCallback)
        eventSink?.success(mapOf("type" to "scan_started"))

        autoStopScanning = mainCoroutineScope.launch {
            delay(SCANNING_DURATION_MS.milliseconds)
            eventSink?.success(mapOf("type" to "scan_timeout"))
            stopScanning()
        }
    }

    private fun stopScanning() {
        isScanning.set(false)
        autoStopScanning?.cancel()
        autoStopScanning = null
        adapter?.bluetoothLeScanner?.stopScan(scanCallback)
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        // Dart stopped listening (cancelled or left the screen): don't scan for nobody.
        eventSink = null
        stopScanning()
    }
}
