import 'package:ble_chat/domain/entities/connect_session_progress.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:equatable/equatable.dart';

enum ConnectSessionStatus {
  connecting,
  connected,
  failed,
  disconnecting,
  disconnected,
}

class ConnectSessionState extends Equatable {
  const ConnectSessionState({
    required this.room,
    required this.authCode,
    this.status = ConnectSessionStatus.connecting,
    this.step = ConnectSessionProgressStep.connect,
    this.progress = const [],
  });

  final FoundRoom room;
  final String authCode;
  final ConnectSessionStatus status;
  final ConnectSessionProgressStep step;

  /// The startup steps and where each one is. Empty until connecting starts.
  final List<ConnectSessionProgress> progress;

  ConnectSessionState copyWith({
    ConnectSessionStatus? status,
    ConnectSessionProgressStep? step,
    List<ConnectSessionProgress>? progress,
  }) {
    return ConnectSessionState(
      room: room,
      authCode: authCode,
      status: status ?? this.status,
      step: step ?? this.step,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [status, step, progress];
}
