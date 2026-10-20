import 'package:ble_chat/domain/entities/advertiser_event.dart';

abstract class HostSessionRepository {
  Stream<AdvertiserEvent> hostSessionEvents();

  Future<void> start({required String name, required String code});

  Future<void> stop();
}
