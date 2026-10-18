sealed class JoinRoomEvent {}

final class ScanRoomEvent extends JoinRoomEvent {
  ScanRoomEvent(this.roomName);

  final String roomName;
}

final class StopScanRoomEvent extends JoinRoomEvent {}

final class JoinRoom extends JoinRoomEvent {
  JoinRoom(this.code);

  final String code;
}
