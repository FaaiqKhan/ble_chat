import 'package:ble_chat/domain/repository/join_room_repository.dart';

class JoinRoomRepositoryImpl implements JoinRoomRepository {
  @override
  Future<void> startScanning(String name) async {}

  @override
  Future<void> stopScanning() async {}

  @override
  Future<void> joinRoom() async {}

  @override
  Future<void> leaveRoom() async {}
}
