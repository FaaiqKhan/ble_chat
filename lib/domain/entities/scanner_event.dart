/// What the native scanner reports while a search is running.
sealed class ScannerEvent {
  const ScannerEvent();

  /// Parses a message from the event channel. Messages it doesn't know become
  /// [UnknownScannerEvent] so a new native event can't break the stream.
  factory ScannerEvent.fromMap(Map<dynamic, dynamic> map) {
    return switch (map["type"]) {
      "scan_started" => const ScannerStartedEvent(),
      "scan_timeout" => const ScannerTimeoutEvent(),
      "scan_result" => ScannerResultEvent(
        identity: map["name"] as String,
        address: map["address"] as String,
        rssi: (map["rssi"] as num).toInt(),
      ),
      _ => const UnknownScannerEvent(),
    };
  }

  /// Parses an error sent with `EventSink.error`.
  factory ScannerEvent.fromError(String code, String? message) =>
      ScannerFailedEvent(code: code, message: message);
}

/// The radio is scanning.
class ScannerStartedEvent extends ScannerEvent {
  const ScannerStartedEvent();
}

/// A room matching the search was found.
class ScannerResultEvent extends ScannerEvent {
  const ScannerResultEvent({
    required this.identity,
    required this.address,
    required this.rssi,
  });

  /// What the host advertises: "RoomName · CODE".
  final String identity;
  final String address;
  final int rssi;

  static const _separator = ' · ';

  String get roomName {
    final i = identity.lastIndexOf(_separator);
    return i < 0 ? identity : identity.substring(0, i);
  }

  String get roomCode {
    final i = identity.lastIndexOf(_separator);
    return i < 0 ? '' : identity.substring(i + _separator.length);
  }
}

/// The scan ran its full time without finding a match.
class ScannerTimeoutEvent extends ScannerEvent {
  const ScannerTimeoutEvent();
}

/// The scan couldn't run (Bluetooth off, scanner refused, ...).
class ScannerFailedEvent extends ScannerEvent {
  const ScannerFailedEvent({required this.code, this.message});

  final String code;
  final String? message;
}

class UnknownScannerEvent extends ScannerEvent {
  const UnknownScannerEvent();
}
