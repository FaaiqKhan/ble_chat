sealed class ScanSessionEvent {}

final class ScanRoomEvent extends ScanSessionEvent {
  ScanRoomEvent({required this.roomName, required this.roomCode});

  final String roomName;
  final String roomCode;
}

final class StopScanRoomEvent extends ScanSessionEvent {}

final class JoinRoom extends ScanSessionEvent {
  JoinRoom(this.code);

  final String code;
}
