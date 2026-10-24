import 'package:ble_chat/domain/entities/connect_session_progress.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:equatable/equatable.dart';

class ConnectSessionState extends Equatable {
  const ConnectSessionState({
    required this.room,
    required this.authCode,
    this.connectionState = ConnectSessionStatus.connecting,
    this.connectionStep = ConnectSessionProgressStep.connect,
  });

  final FoundRoom room;
  final String authCode;
  final ConnectSessionStatus connectionState;
  final ConnectSessionProgressStep connectionStep;

  ConnectSessionState copyWith({
    ConnectSessionStatus? connectionState,
    ConnectSessionProgressStep? connectionStep,
  }) {
    return ConnectSessionState(
      room: room,
      authCode: authCode,
      connectionState: connectionState ?? this.connectionState,
      connectionStep: connectionStep ?? this.connectionStep,
    );
  }

  @override
  List<Object?> get props => [connectionState, connectionStep];
}
