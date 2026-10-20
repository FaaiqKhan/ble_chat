abstract class ScanRoomRepository {
  Future<void> startScanning({required String name, required String code});

  Future<void> stopScanning();
}
