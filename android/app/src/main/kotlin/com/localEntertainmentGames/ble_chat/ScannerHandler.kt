package com.localEntertainmentGames.ble_chat

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class ScannerHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val EVENT_CHANNEL = "bleScanner/events"
        const val METHOD_CHANNEL = "bleScanner/methods"
        private const val SCANNING_DURATION_MS = 10_000L
    }

    private val isScanning: AtomicBoolean = AtomicBoolean(false)

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "scan" -> {}
            "stop" -> {}
            else -> result.notImplemented()
        }
    }

    private fun startScanning(roomName: String) {

    }
}