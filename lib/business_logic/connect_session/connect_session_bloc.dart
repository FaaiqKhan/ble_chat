import 'dart:async';

import 'package:ble_chat/business_logic/connect_session/connect_session_event.dart';
import 'package:ble_chat/business_logic/connect_session/connect_session_state.dart';
import 'package:ble_chat/domain/entities/connect_session_progress.dart';
import 'package:ble_chat/domain/repository/connect_session_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectSessionBloc
    extends Bloc<ConnectSessionEvent, ConnectSessionState> {
  ConnectSessionBloc(
    super.initialState, {
    required this._connectSessionRepository,
  }) {
    on<ConnectChatSessionEvent>(_onConnectChatSessionEvent);
    on<DisconnectChatSessionEvent>(_onDisconnectChatSessionEvent);
  }

  final ConnectSessionRepository _connectSessionRepository;

  Future<void> _onConnectChatSessionEvent(
    ConnectChatSessionEvent event,
    Emitter<ConnectSessionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ConnectSessionStatus.connecting,
        progress: ConnectSessionProgress.initial(),
      ),
    );

    // Listen before asking native to start, so no early event is missed.
    final events = emit.forEach(
      _connectSessionRepository.connectSessionEvents(),
      onData: _stateFor,
    );
    try {
      await _connectSessionRepository.connect(state.room, state.authCode);
    } catch (_) {
      emit(_failedAt(ConnectSessionProgressStep.connect));
    }
    await events;
  }

  ConnectSessionState _stateFor(dynamic event) => switch (event) {
    // TODO: Handle this case.
    Object() => throw UnimplementedError(),
    // TODO: Handle this case.
    null => throw UnimplementedError(),
  };

  ConnectSessionState _failedAt(ConnectSessionProgressStep step) =>
      state.copyWith(status: ConnectSessionStatus.failed, step: step);

  Future<void> _onDisconnectChatSessionEvent(
    DisconnectChatSessionEvent event,
    Emitter<ConnectSessionState> emit,
  ) async {
    emit(state.copyWith(status: ConnectSessionStatus.disconnecting));
    try {
      await _connectSessionRepository.disconnect();
    } finally {
      emit(state.copyWith(status: ConnectSessionStatus.disconnected));
    }
  }
}
