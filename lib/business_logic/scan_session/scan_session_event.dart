import 'package:ble_chat/domain/entities/scanner_event.dart';

sealed class ScanSessionEvent {}

final class ScanRoomEvent extends ScanSessionEvent {
  ScanRoomEvent(this.query);

  /// Part of the room name, or its code.
  final String query;
}

final class StopScanRoomEvent extends ScanSessionEvent {}

/// Wraps something native reported so the bloc handles it like any other
/// event. Added by the bloc itself, not by the UI.
final class ScanEventReceived extends ScanSessionEvent {
  ScanEventReceived(this.event);

  final ScannerEvent event;
}
