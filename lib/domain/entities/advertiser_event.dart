import 'package:ble_chat/domain/entities/host_session_progress.dart';

/// What the native advertiser reports while a room is starting.
sealed class AdvertiserEvent {
  const AdvertiserEvent();

  /// Parses a message from the event channel. Messages it doesn't know become
  /// [UnknownAdvertiserEvent] so a new native event can't break the stream.
  factory AdvertiserEvent.fromMap(Map<dynamic, dynamic> map) {
    if (map["type"] != "progress") return const UnknownAdvertiserEvent();
    final step = switch (map["state"]) {
      "bluetoothReady" => HostSessionProgressStep.bluetooth,
      "serviceCreated" => HostSessionProgressStep.service,
      "advertisingStarted" => HostSessionProgressStep.advertising,
      _ => null,
    };
    return step == null
        ? const UnknownAdvertiserEvent()
        : HostSessionProgressEvent(step: step);
  }

  /// Parses an error sent with `EventSink.error`; [code] says which step.
  factory AdvertiserEvent.fromError(String code, String? message) {
    final step = switch (code) {
      "bluetooth" => HostSessionProgressStep.bluetooth,
      "create_room_service" => HostSessionProgressStep.service,
      _ => HostSessionProgressStep.advertising,
    };
    return HostSessionFailedEvent(step: step, message: message);
  }
}

/// [step] has finished.
class HostSessionProgressEvent extends AdvertiserEvent {
  const HostSessionProgressEvent({required this.step});

  final HostSessionProgressStep step;
}

/// [step] failed, so the room can't start.
class HostSessionFailedEvent extends AdvertiserEvent {
  const HostSessionFailedEvent({required this.step, this.message});

  final HostSessionProgressStep step;
  final String? message;
}

class UnknownAdvertiserEvent extends AdvertiserEvent {
  const UnknownAdvertiserEvent();
}
