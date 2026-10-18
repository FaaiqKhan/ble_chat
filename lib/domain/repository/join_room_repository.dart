abstract class JoinRoomRepository {
  Future<void> startScanning(String name);

  Future<void> stopScanning();

  Future<void> joinRoom();

  Future<void> leaveRoom();
}
