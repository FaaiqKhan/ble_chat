package com.localEntertainmentGames.ble_chat

object Utils {
    const val IDENTITY_SEPARATOR = " · "


    fun buildRoomIdentity(roomName: String, roomCode: String): String {
        return "$roomName$IDENTITY_SEPARATOR$roomCode"
    }

    private const val CODE_LENGTH = 4

    // The whole advertising packet is 31 bytes: 3 for flags, 4 for the manufacturer-data
    // header, leaving 24 for the payload.
    private const val MAX_PAYLOAD = 24

    /**
     * Payload of the advertising packet: marker, 4-byte code, then the room name.
     * Null if the code isn't 4 characters or it wouldn't fit in the packet.
     */
    fun encodeAdvertisement(roomName: String, roomCode: String): ByteArray? {
        val code = roomCode.toByteArray(Charsets.US_ASCII)
        if (code.size != CODE_LENGTH) return null
        val payload = byteArrayOf(Constants.ADVERTISEMENT_MARKER) + code +
                roomName.toByteArray(Charsets.UTF_8)
        return payload.takeIf { it.size <= MAX_PAYLOAD }
    }

    /** Reverse of [encodeAdvertisement]: the room identity ("Name · CODE"), or null. */
    fun decodeAdvertisement(payload: ByteArray?): String? {
        if (payload == null || payload.size <= 1 + CODE_LENGTH) return null
        if (payload[0] != Constants.ADVERTISEMENT_MARKER) return null
        val code = String(payload, 1, CODE_LENGTH, Charsets.US_ASCII)
        val name = String(payload, 1 + CODE_LENGTH, payload.size - 1 - CODE_LENGTH, Charsets.UTF_8)
        return buildRoomIdentity(name, code)
    }

    fun getRoomDetails(data: Any?): Map<String, String?>? {
        if (data == null || data !is Map<*, *>) return null
        return mapOf(
            "name" to data["roomName"] as String?,
            "code" to data["roomCode"] as String?
        )
    }
}