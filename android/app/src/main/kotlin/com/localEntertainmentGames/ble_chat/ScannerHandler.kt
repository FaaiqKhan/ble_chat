package com.localEntertainmentGames.ble_chat

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.SystemClock
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
 *  - `scan_result`: a room with a matching name was seen. Several rooms can share a name,
 *    so one is sent per host, and again for the same host at most every
 *    [REPORT_INTERVAL_MS] so Dart can keep its signal strength up to date
 *  - `scan_timeout`: the scan is over. Without a match that is after [SCANNING_DURATION_MS];
 *    once rooms are listed the scan keeps going (live signal) up to [MAX_SCANNING_DURATION_MS]
 *  - errors (`EventSink.error`): `bluetooth`, `scan_failed`
 */
@SuppressLint("MissingPermission")
class ScannerHandler(context: Context) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val EVENT_CHANNEL = "bleScanner/events"
        const val METHOD_CHANNEL = "bleScanner/methods"
        private const val SCANNING_DURATION_MS = 10_000L
        private const val MAX_SCANNING_DURATION_MS = 60_000L

        // Minimum gap between two reports of the same host.
        private const val REPORT_INTERVAL_MS = 1_000L
    }

    private val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private val adapter get() = bluetoothManager?.adapter
    private var eventSink: EventChannel.EventSink? = null
    private var autoStopScanning: Job? = null
    private val mainCoroutineScope: CoroutineScope = MainScope()

    // Scan callbacks arrive on a Binder thread, so these are read across threads.
    private val isScanning = AtomicBoolean(false)

    // Host address -> the earliest time (elapsedRealtime) it may be reported again. A host
    // advertises many times a second, so most results are dropped. Written from the
    // Binder thread and read from the main thread, hence the concurrent map.
    private val nextReportAt = ConcurrentHashMap<String, Long>()

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
                    result.error("invalid_argument", "A room name is required", null)
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
            // The host advertises its room as manufacturer data (see Utils.encodeAdvertisement).
            val room = Utils.decodeAdvertisement(
                record.getManufacturerSpecificData(Constants.MANUFACTURER_ID)
            ) ?: return
            // Only the name is searched, so a code can't make a different room match.
            if (!room.name.contains(query, ignoreCase = true)) return
            val address = result.device.address

            // Decide atomically: a new host, or one whose interval has passed, is reported.
            val now = SystemClock.elapsedRealtime()
            var report = false
            nextReportAt.compute(address) { _, next ->
                if (next == null || now >= next) {
                    report = true
                    now + REPORT_INTERVAL_MS
                } else {
                    next
                }
            }
            if (!report) return

            val event = mapOf(
                "type" to "scan_result",
                "address" to address,
                "name" to room.identity,
                "rssi" to result.rssi,
                "people" to room.people,
                "maxPeople" to room.maxPeople,
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
        nextReportAt.clear()

        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        // Filtered in hardware: only advertisements with our company id and marker byte
        // reach the app. The room name is then compared in onScanResult.
        val scanFilters = listOf(
            ScanFilter.Builder()
                .setManufacturerData(
                    Constants.MANUFACTURER_ID,
                    byteArrayOf(Constants.ADVERTISEMENT_MARKER),
                    byteArrayOf(0xFF.toByte())
                )
                .build()
        )
        scanner.startScan(scanFilters, scanSettings, scanCallback)
        eventSink?.success(mapOf("type" to "scan_started"))

        autoStopScanning = mainCoroutineScope.launch {
            delay(SCANNING_DURATION_MS.milliseconds)
            // With rooms listed the scan carries on so their signal stays live,
            // up to a cap so it can't run (and drain the battery) forever.
            if (nextReportAt.isNotEmpty()) {
                delay((MAX_SCANNING_DURATION_MS - SCANNING_DURATION_MS).milliseconds)
            }
            // Dart decides from its own list whether anything was found.
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
        // Dart stopped listening (canceled or left the screen): don't scan for nobody.
        eventSink = null
        stopScanning()
    }
}
