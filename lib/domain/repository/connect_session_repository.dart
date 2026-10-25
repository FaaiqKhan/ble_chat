import 'package:ble_chat/domain/entities/connect_event.dart';
import 'package:ble_chat/domain/entities/found_room.dart';

abstract class ConnectSessionRepository {
  Future<void> connect(FoundRoom room, String authCode);

  Stream<ConnectEvent> connectSessionEvents();

  Future<void> disconnect();
}
