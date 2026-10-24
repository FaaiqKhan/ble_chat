import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:equatable/equatable.dart';

enum ChatSessionConnectionState { connecting, connected, failed }

enum ChatSessionConnectionStep { connect, authenticate, discover, join }

class ChatSessionState extends Equatable {
  const ChatSessionState({
    required this.room,
    required this.authCode,
    this.connectionState = ChatSessionConnectionState.connecting,
    this.connectionStep = ChatSessionConnectionStep.connect,
  });

  final FoundRoom room;
  final String authCode;
  final ChatSessionConnectionState connectionState;
  final ChatSessionConnectionStep connectionStep;

  ChatSessionState copyWith({
    ChatSessionConnectionState? connectionState,
    ChatSessionConnectionStep? connectionStep,
  }) {
    return ChatSessionState(
      room: room,
      authCode: authCode,
      connectionState: connectionState ?? this.connectionState,
      connectionStep: connectionStep ?? this.connectionStep,
    );
  }

  @override
  List<Object?> get props => [connectionState, connectionStep];
}
