import 'package:ble_chat/domain/entities/connect_session_progress.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:equatable/equatable.dart';

enum ConnectSessionStatus {
  connecting,
  connected,
  failed,
  disconnecting,
  disconnected,

  /// The link dropped after the room had been joined (the host left, went out
  /// of range, or closed the room).
  lost,
}

class ConnectSessionState extends Equatable {
  const ConnectSessionState({
    required this.room,
    required this.authCode,
    this.status = ConnectSessionStatus.connecting,
    this.step = ConnectSessionProgressStep.connect,
    this.progress = const [],
    this.rssi,
    this.errorCode,
    this.errorMessage,
  });

  final FoundRoom room;
  final String authCode;
  final ConnectSessionStatus status;
  final ConnectSessionProgressStep step;

  /// The startup steps and where each one is. Empty until connecting starts.
  final List<ConnectSessionProgress> progress;

  /// Live signal strength of the link to the host. Null until a reading arrives,
  /// so [signal] falls back to what the scan saw.
  final int? rssi;
  int get signal => rssi ?? room.rssi;

  /// Why joining failed (native's error code), e.g. `wrong_code`.
  final String? errorCode;
  final String? errorMessage;

  bool get isWrongCode => errorCode == "wrong_code";

  ConnectSessionState copyWith({
    ConnectSessionStatus? status,
    ConnectSessionProgressStep? step,
    List<ConnectSessionProgress>? progress,
    int? rssi,
    String? errorCode,
    String? errorMessage,
  }) {
    return ConnectSessionState(
      room: room,
      authCode: authCode,
      status: status ?? this.status,
      step: step ?? this.step,
      progress: progress ?? this.progress,
      rssi: rssi ?? this.rssi,
      // Cleared whenever a new status doesn't bring one.
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    step,
    progress,
    rssi,
    errorCode,
    errorMessage,
  ];
}
