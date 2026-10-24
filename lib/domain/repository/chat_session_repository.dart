import 'package:ble_chat/domain/entities/found_room.dart';

abstract class ChatSessionRepository {
  Future<void> connect(FoundRoom room, String authCode);

  Future<void> updateConnectStatus(FoundRoom room);

  Future<void> listenRoomSignal(FoundRoom room);

  Future<void> disconnect();
}
