import 'package:ble_chat/domain/entities/found_room.dart';

abstract class ConnectSessionRepository {
  Future<void> connect(FoundRoom room, String authCode);

  /// Create class for strict typing of data
  /// Name of the class will be ConnectEvent
  Stream<dynamic> connectSessionEvents();

  Future<void> disconnect();
}
