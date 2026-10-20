package com.localEntertainmentGames.ble_chat

object Utils {
    const val IDENTITY_SEPARATOR = " · "


    fun buildRoomIdentity(roomName: String, roomCode: String): String {
        return "$roomName$IDENTITY_SEPARATOR$roomCode"
    }

    fun getRoomDetails(data: Any?): Map<String, String?>? {
        if (data == null || data !is Map<*, *>) return null
        return mapOf(
            "name" to data["roomName"] as String?,
            "code" to data["roomCode"] as String?
        )
    }
}