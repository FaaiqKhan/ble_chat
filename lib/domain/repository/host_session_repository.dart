import 'package:ble_chat/domain/entities/advertiser_event.dart';

abstract class HostSessionRepository {
  Stream<AdvertiserEvent> hostSessionEvents();

  Future<void> start(String roomName);

  Future<void> stop();
}
