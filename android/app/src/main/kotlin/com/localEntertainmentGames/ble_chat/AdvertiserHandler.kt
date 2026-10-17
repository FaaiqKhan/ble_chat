package com.localEntertainmentGames.ble_chat

import android.content.Context
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Turns the device into a BLE peripheral: it advertises a service and runs a GATT server
 * exposing one characteristic (read / write / notify) that central devices can connect to.
 *
 * Callers must hold BLUETOOTH_ADVERTISE and BLUETOOTH_CONNECT (Android 12+) before calling.
 */
class AdvertiserHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        TODO("Not yet implemented")
    }
}