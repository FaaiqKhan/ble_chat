abstract class JoinRoomRepository {
  Future<void> startScanning({required String name, required String code});

  Future<void> stopScanning();

  Future<void> joinRoom();

  Future<void> leaveRoom();
}
