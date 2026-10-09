package com.localEntertainmentGames.ble_chat

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BluetoothPermissionHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "bluetoothPermission"
    }

    val adapter: BluetoothAdapter? = context.getSystemService(BluetoothManager::class.java)?.adapter

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (call.method == "openBluetoothSettings") {
            context.startActivity(
                Intent(Settings.ACTION_BLUETOOTH_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            result.success(null)
            return
        }

        if (adapter == null) {
            result.error(
                "unsupported",
                "Bluetooth is not available on this device",
                null
            )
            return
        }

        when (call.method) {
            "bluetoothStatus" -> result.success(adapter.isEnabled)
            else -> result.notImplemented()
        }
    }
}