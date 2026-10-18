package com.localEntertainmentGames.ble_chat

import java.util.UUID

object Constants {
    val SERVICE_UUID: UUID = UUID.fromString("0000feed-0000-1000-8000-00805f9b34fb")
    val CHARACTERISTIC_UUID: UUID = UUID.fromString("0000beef-0000-1000-8000-00805f9b34fb")
    val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
}