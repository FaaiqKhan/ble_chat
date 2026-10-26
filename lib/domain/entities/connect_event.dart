import 'package:ble_chat/domain/entities/connect_session_progress.dart';

/// What the native connector reports while joining a room.
sealed class ConnectEvent {
  const ConnectEvent();

  /// Parses a message from the event channel. Messages it doesn't know (chat
  /// messages, "connecting", ...) become [UnknownConnectEvent].
  factory ConnectEvent.fromMap(Map<dynamic, dynamic> map) {
    switch (map["type"]) {
      case "progress":
        final step = switch (map["step"]) {
          "connect" => ConnectSessionProgressStep.connect,
          "discover" => ConnectSessionProgressStep.discover,
          "authenticate" => ConnectSessionProgressStep.authenticate,
          "join" => ConnectSessionProgressStep.join,
          _ => null,
        };
        return step == null
            ? const UnknownConnectEvent()
            : ConnectStepDoneEvent(step: step);
      case "host":
        return ConnectHostNameEvent(name: map["name"] as String);
      case "rssi":
        return ConnectRssiEvent(rssi: (map["rssi"] as num).toInt());
      case "connection" when map["status"] == "disconnected":
        return const ConnectDisconnectedEvent();
      default:
        return const UnknownConnectEvent();
    }
  }

  /// Parses an error sent with `EventSink.error`; [code] says what went wrong.
  factory ConnectEvent.fromError(String code, String? message) =>
      ConnectFailedEvent(code: code, message: message);
}

/// [step] has finished.
class ConnectStepDoneEvent extends ConnectEvent {
  const ConnectStepDoneEvent({required this.step});

  final ConnectSessionProgressStep step;
}

/// The name of the person hosting the room. Read from the host after connecting,
/// because it doesn't fit in the advertisement.
class ConnectHostNameEvent extends ConnectEvent {
  const ConnectHostNameEvent({required this.name});

  final String name;
}

/// A new reading of the link's signal strength (dBm), once joined.
class ConnectRssiEvent extends ConnectEvent {
  const ConnectRssiEvent({required this.rssi});

  final int rssi;
}

/// The link to the host is gone.
class ConnectDisconnectedEvent extends ConnectEvent {
  const ConnectDisconnectedEvent();
}

/// Joining failed. [code] is one of native's error codes (`wrong_code`,
/// `service_not_found`, `connection_failed`, ...).
class ConnectFailedEvent extends ConnectEvent {
  const ConnectFailedEvent({required this.code, this.message});

  final String code;
  final String? message;

  /// The step that was being done when it failed.
  ConnectSessionProgressStep get step => switch (code) {
    "service_not_found" ||
    "service_discovery_failed" => ConnectSessionProgressStep.discover,
    "wrong_code" || "auth_failed" => ConnectSessionProgressStep.authenticate,
    "notify_failed" => ConnectSessionProgressStep.join,
    _ => ConnectSessionProgressStep.connect,
  };

  bool get isWrongCode => code == "wrong_code";
}

class UnknownConnectEvent extends ConnectEvent {
  const UnknownConnectEvent();
}
