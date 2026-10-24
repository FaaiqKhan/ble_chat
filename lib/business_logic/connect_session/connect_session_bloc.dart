import 'dart:async';

import 'package:ble_chat/business_logic/connect_session/connect_session_event.dart';
import 'package:ble_chat/business_logic/connect_session/connect_session_state.dart';
import 'package:ble_chat/domain/repository/connect_session_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectSessionBloc
    extends Bloc<ConnectSessionEvent, ConnectSessionState> {
  ConnectSessionBloc(
    super.initialState, {
    required this._chatSessionRepository,
  }) {
    on<ConnectChatSessionEvent>(_onConnectChatSessionEvent);
    on<DisconnectChatSessionEvent>(_onDisconnectChatSessionEvent);
  }

  final ConnectSessionRepository _chatSessionRepository;

  Future<void> _onConnectChatSessionEvent(
    ConnectChatSessionEvent event,
    Emitter<ConnectSessionState> emit,
  ) async {
    _chatSessionRepository.connect(state.room, state.authCode);
  }

  Future<void> _onDisconnectChatSessionEvent(
    DisconnectChatSessionEvent event,
    Emitter<ConnectSessionState> emit,
  ) async {}
}
