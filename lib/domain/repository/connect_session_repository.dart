import 'package:ble_chat/domain/entities/found_room.dart';

abstract class ConnectSessionRepository {
  Future<void> connect(FoundRoom room, String authCode);

  Future<void> updateConnectStatus(FoundRoom room);

  Future<void> listenRoomSignal(FoundRoom room);

  Future<void> disconnect();
}
