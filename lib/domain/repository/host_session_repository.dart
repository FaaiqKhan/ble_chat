import 'package:ble_chat/domain/entities/advertiser_event.dart';

abstract class HostSessionRepository {
  Stream<AdvertiserEvent> hostSessionEvents();

  Future<void> start({
    required String name,
    required String code,
    required int maxPeople,
  });

  /// Tells nearby scanners how many people are in the room now, so they can
  /// show it as full.
  Future<void> updatePeople(int people);

  Future<void> stop();
}
