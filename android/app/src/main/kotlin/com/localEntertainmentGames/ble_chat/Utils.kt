package com.localEntertainmentGames.ble_chat

object Utils {
    const val IDENTITY_SEPARATOR = " · "

    private const val CODE_LENGTH = 4

    // Payload layout: marker, people, max, 4-byte code, then the room name.
    private const val HEADER_LENGTH = 3
    private const val NAME_OFFSET = HEADER_LENGTH + CODE_LENGTH

    // The whole advertising packet is 31 bytes: 3 for flags, 4 for the manufacturer-data
    // header, leaving 24 for the payload (so a name of up to 17 bytes).
    private const val MAX_PAYLOAD = 24

    /** A room as it is advertised. */
    data class RoomAd(val name: String, val code: String, val people: Int, val maxPeople: Int) {
        val identity: String get() = buildRoomIdentity(name, code)
    }

    fun buildRoomIdentity(roomName: String, roomCode: String): String {
        return "$roomName$IDENTITY_SEPARATOR$roomCode"
    }

    /**
     * Payload of the advertising packet. Null if the code isn't 4 characters, the counts
     * don't fit a byte, or everything wouldn't fit in the packet.
     */
    fun encodeAdvertisement(room: RoomAd): ByteArray? {
        val code = room.code.toByteArray(Charsets.US_ASCII)
        if (code.size != CODE_LENGTH) return null
        if (room.people !in 0..255 || room.maxPeople !in 0..255) return null
        val payload = byteArrayOf(
            Constants.ADVERTISEMENT_MARKER,
            room.people.toByte(),
            room.maxPeople.toByte(),
        ) + code + room.name.toByteArray(Charsets.UTF_8)
        return payload.takeIf { it.size <= MAX_PAYLOAD }
    }

    /** Reverse of [encodeAdvertisement]; null if this isn't one of our advertisements. */
    fun decodeAdvertisement(payload: ByteArray?): RoomAd? {
        if (payload == null || payload.size <= NAME_OFFSET) return null
        if (payload[0] != Constants.ADVERTISEMENT_MARKER) return null
        return RoomAd(
            name = String(payload, NAME_OFFSET, payload.size - NAME_OFFSET, Charsets.UTF_8),
            code = String(payload, HEADER_LENGTH, CODE_LENGTH, Charsets.US_ASCII),
            people = payload[1].toInt() and 0xFF,
            maxPeople = payload[2].toInt() and 0xFF,
        )
    }

    /** Arguments of the advertiser's `start` call, or null if they aren't a map. */
    fun getRoomDetails(data: Any?): RoomAd? {
        if (data == null || data !is Map<*, *>) return null
        val name = data["roomName"] as? String
        val code = data["roomCode"] as? String
        if (name.isNullOrEmpty() || code.isNullOrEmpty()) return null
        return RoomAd(
            name = name,
            code = code,
            people = (data["people"] as? Int) ?: 1,
            maxPeople = (data["maxPeople"] as? Int) ?: 0,
        )
    }
}
