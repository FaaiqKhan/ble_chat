package com.localEntertainmentGames.ble_chat

import java.util.UUID

object Constants {
    val SERVICE_UUID: UUID = UUID.fromString("0000feed-0000-1000-8000-00805f9b34fb")
    val CHARACTERISTIC_UUID: UUID = UUID.fromString("0000beef-0000-1000-8000-00805f9b34fb")

    // Company id the room identity is advertised under (0xFFFF is reserved for testing).
    const val MANUFACTURER_ID = 0xFFFF

    // First payload byte of our advertisement. Scans filter on company id + this byte in
    // hardware, so other devices' advertisements never reach the app.
    const val ADVERTISEMENT_MARKER: Byte = 0x4C

    val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    // Write-only: a guest writes the 6-digit join code here right after connecting.
    val AUTH_CHARACTERISTIC_UUID: UUID = UUID.fromString("0000cafe-0000-1000-8000-00805f9b34fb")
    // Read-only: the name of the person hosting the room, read by a guest after joining.
    val HOST_NAME_UUID: UUID = UUID.fromString("0000c00c-0000-1000-8000-00805f9b34fb")
}