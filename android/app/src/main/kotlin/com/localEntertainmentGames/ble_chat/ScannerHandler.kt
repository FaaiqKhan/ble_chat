package com.localEntertainmentGames.ble_chat

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration.Companion.milliseconds

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
    private val isFound: AtomicBoolean = AtomicBoolean(false)
    private val isScanning: AtomicBoolean = AtomicBoolean(false)

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "scan" -> {
                result.success(null)
                val roomDetails = Utils.getRoomDetails(call.arguments())
                if (roomDetails.isNullOrEmpty()) {
                    eventSink?.error(
                        "invalid_format",
                        "Argument must be a Map that contains roomName and roomCode",
                        null
                    )
                    return
                }
                if (roomDetails["name"].isNullOrEmpty() || roomDetails["code"].isNullOrEmpty()) {
                    eventSink?.error(
                        "scan_room",
                        "Room name and code are required",
                        null
                    )
                    return
                }
                val roomName = roomDetails["name"] as String
                val roomCode = roomDetails["code"] as String
                if (isScanning.compareAndSet(false, true)) {
                    startScanning(Utils.buildRoomIdentity(roomName, roomCode))
                } else {
                    result.error("already_scanning", "A scan is already running", null)
                }
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
            if (!isFound.compareAndSet(false, true)) {
                return
            }
            if (result == null) return
            val event = mapOf(
                "type" to "scan_result",
                "address" to result.device.address,
                "name" to (result.scanRecord?.deviceName ?: result.device.name),
                "rssi" to result.rssi,
                "serviceUuids" to (result.scanRecord?.serviceUuids?.map { it.toString() }
                    ?: emptyList()),
            )
            mainCoroutineScope.launch {
                eventSink?.success(event)
                stopScanning()
            }
        }

        override fun onScanFailed(errorCode: Int) {
            if (!isFound.compareAndSet(false, true)) return
            mainCoroutineScope.launch {
                stopScanning()
                eventSink?.error(
                    "scan_failed",
                    "Scan failed with code $errorCode",
                    errorCode
                )
            }
        }
    }

    private fun startScanning(roomIdentity: String) {
        val scanner = adapter?.takeIf { it.isEnabled }?.bluetoothLeScanner
        if (scanner == null) {
            eventSink?.error("bluetooth", "Bluetooth is not available", null)
            return
        }
        val scanSetting = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        val scanFilters = listOf(
            ScanFilter.Builder()
                .setDeviceName(roomIdentity).build()
        )
        scanner.startScan(scanFilters, scanSetting, scanCallback)
        autoStopScanning = mainCoroutineScope.launch {
            delay(SCANNING_DURATION_MS.milliseconds)
            stopScanning()
        }
    }

    private fun stopScanning() {
        isFound.set(false)
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
        eventSink = null
    }
}