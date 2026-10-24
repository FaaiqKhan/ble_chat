package com.localEntertainmentGames.ble_chat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Kept so they can be released when the engine goes away.
    private var advertiserHandler: AdvertiserHandler? = null
    private var scannerHandler: ScannerHandler? = null
    private var connectHandler: ConnectHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BluetoothPermissionHandler.CHANNEL
        ).setMethodCallHandler(BluetoothPermissionHandler(applicationContext))


        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BluetoothStateHandler.CHANNEL
        ).setStreamHandler(BluetoothStateHandler(applicationContext))

        val advertiserHandler = AdvertiserHandler(applicationContext)
        this.advertiserHandler = advertiserHandler
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AdvertiserHandler.EVENT_CHANNEL
        ).setStreamHandler(advertiserHandler)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AdvertiserHandler.METHOD_CHANNEL
        ).setMethodCallHandler(advertiserHandler)

        val scannerHandler = ScannerHandler(applicationContext)
        this.scannerHandler = scannerHandler
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ScannerHandler.EVENT_CHANNEL
        ).setStreamHandler(scannerHandler)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ScannerHandler.METHOD_CHANNEL
        ).setMethodCallHandler(scannerHandler)

        val connectHandler = ConnectHandler(applicationContext)
        this.connectHandler = connectHandler
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ConnectHandler.EVENT_CHANNEL
        ).setStreamHandler(connectHandler)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ConnectHandler.METHOD_CHANNEL
        ).setMethodCallHandler(connectHandler)
    }

    // Called when the engine is torn down with the activity. Without this the radio would
    // keep advertising / scanning / connected, and the handlers' threads and timers would
    // outlive the screen.
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        advertiserHandler?.release()
        advertiserHandler = null
        scannerHandler?.release()
        scannerHandler = null
        connectHandler?.release()
        connectHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
