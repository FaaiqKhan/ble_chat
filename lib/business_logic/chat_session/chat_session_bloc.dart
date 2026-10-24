import 'dart:async';

import 'package:ble_chat/business_logic/chat_session/chat_session_event.dart';
import 'package:ble_chat/business_logic/chat_session/chat_session_state.dart';
import 'package:ble_chat/domain/repository/chat_session_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatSessionBloc extends Bloc<ChatSessionEvent, ChatSessionState> {
  ChatSessionBloc(super.initialState, {required this._chatSessionRepository}) {
    on<ConnectChatSessionEvent>(_onConnectChatSessionEvent);
    on<DisconnectChatSessionEvent>(_onDisconnectChatSessionEvent);
  }

  final ChatSessionRepository _chatSessionRepository;

  Future<void> _onConnectChatSessionEvent(
    ConnectChatSessionEvent event,
    Emitter<ChatSessionState> emit,
  ) async {
    _chatSessionRepository.connect(state.room, state.authCode);
  }

  Future<void> _onDisconnectChatSessionEvent(
    DisconnectChatSessionEvent event,
    Emitter<ChatSessionState> emit,
  ) async {}
}
