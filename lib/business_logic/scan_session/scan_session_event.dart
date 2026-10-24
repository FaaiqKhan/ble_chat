import 'package:ble_chat/domain/entities/scanner_event.dart';

sealed class ScanSessionEvent {}

final class ScanRoomEvent extends ScanSessionEvent {
  ScanRoomEvent(this.query);

  /// Part of the room name, or its code.
  final String query;
}

/// Cancel: stops the scan and clears everything, back to the empty start.
final class StopScanRoomEvent extends ScanSessionEvent {}

/// Stops the scan but keeps the rooms found so far on screen, e.g. when the user
/// picks one and moves on to connect (a scan running during a connection makes
/// connecting less reliable).
final class PauseScanEvent extends ScanSessionEvent {}

/// Wraps something native reported so the bloc handles it like any other
/// event. Added by the bloc itself, not by the UI.
final class ScanEventReceived extends ScanSessionEvent {
  ScanEventReceived(this.event);

  final ScannerEvent event;
}

/// Ticks while scanning so rooms that went quiet get marked unavailable.
/// Added by the bloc's own timer, not by the UI.
final class StaleRoomsCheck extends ScanSessionEvent {}
