import 'package:ble_chat/common/constants.dart';

/// Rules for the names typed on the room setup screen. Each returns the message to
/// show, or null when the value is fine. Pass the trimmed text.

String? validateRoomName(String value) {
  if (value.isEmpty) return 'Enter a room name';
  if (value.length < 3) return 'Use at least 3 characters';
  if (!validChars.hasMatch(value)) {
    return 'Use letters, numbers, spaces, - _ or . only';
  }
  return null;
}

String? validateHostName(String value) {
  if (value.isEmpty) return 'Enter your name';
  if (value.length < 2) return 'Use at least 2 characters';
  if (!validPlayerNameChars.hasMatch(value)) {
    return "Use letters, spaces, - ' or . only";
  }
  return null;
}
