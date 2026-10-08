package com.localEntertainmentGames.ble_chat

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.plugin.common.EventChannel

class BluetoothStateHandler(private val context: Context) : EventChannel.StreamHandler {
    companion object {
        const val CHANNEL = "bluetoothState/events"
    }

    private var adapter = context.getSystemService(BluetoothManager::class.java)?.adapter
    private var eventSink: EventChannel.EventSink? = null
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(p0: Context?, p1: Intent?) {
            val event = eventSink ?: return
            val adapter = adapter ?: return
            event.success(toValue(adapter.state))
        }
    }

    private fun toValue(state: Int) = when (state) {
        BluetoothAdapter.STATE_ON -> "on"
        BluetoothAdapter.STATE_OFF -> "off"
        BluetoothAdapter.STATE_TURNING_ON -> "turningOn"
        BluetoothAdapter.STATE_TURNING_OFF -> "turningOff"
        else -> "unknown"
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        eventSink = events
        context.registerReceiver(
            receiver,
            IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        )
        // The receiver only fires on changes, so report the current state first.
        val adapter = adapter ?: return
        events?.success(toValue(adapter.state))
    }

    override fun onCancel(arguments: Any?) {
        if (eventSink != null) context.unregisterReceiver(receiver)
        eventSink = null
    }
}