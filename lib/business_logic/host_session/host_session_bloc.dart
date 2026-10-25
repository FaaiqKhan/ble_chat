import 'dart:async';

import 'package:ble_chat/business_logic/host_session/host_session_event.dart';
import 'package:ble_chat/business_logic/host_session/host_session_state.dart';
import 'package:ble_chat/domain/entities/advertiser_event.dart';
import 'package:ble_chat/domain/repository/host_session_repository.dart';
import 'package:ble_chat/domain/entities/host_session_progress.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HostSessionBloc extends Bloc<HostSessionEvent, HostSessionState> {
  HostSessionBloc(super.initialState, {required this._hostSessionRepository}) {
    on<StartHostingEvent>(_onStartHostingEvent);
    on<CloseRoomEvent>(_onCloseRoomEvent);
    on<DismissCloseErrorEvent>(
      (_, emit) => emit(state.copyWith(status: HostSessionStatus.hosting)),
    );
    on<PeerJoinedEvent>(_onPeerJoinedEvent);
    on<PeerSignalStrengthEvent>(_onPeerSignalStrengthEvent);
  }

  final HostSessionRepository _hostSessionRepository;

  int get count => state.participants.length + 1;

  bool get isFull => count >= state.maxPeople;

  int get isOpen => (state.maxPeople - count).clamp(0, state.maxPeople);

  bool get hasPeer => state.participants.isNotEmpty;

  Future<void> _onStartHostingEvent(
    StartHostingEvent event,
    Emitter<HostSessionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HostSessionStatus.starting,
        progress: HostSessionProgress.initial(),
      ),
    );

    // Listen before asking native to start, so no early event is missed.
    final events = emit.forEach<AdvertiserEvent>(
      _hostSessionRepository.hostSessionEvents(),
      onData: _stateFor,
    );
    try {
      await _hostSessionRepository.start(
        name: state.roomName,
        code: state.code,
        maxPeople: state.maxPeople,
      );
    } catch (_) {
      emit(_failedAt(HostSessionProgressStep.bluetooth));
    }
    await events;
  }

  HostSessionState _stateFor(AdvertiserEvent event) => switch (event) {
    // Native confirms teardown while this listener (opened by
    // StartHostingEvent) is still alive.
    HostSessionClosedEvent() => state.copyWith(
      status: HostSessionStatus.closed,
    ),
    HostSessionCloseFailedEvent() => state.copyWith(
      status: HostSessionStatus.closeFailed,
    ),
    // Late progress after a failure or close must not revive the steps.
    _ when state.status != HostSessionStatus.starting => state,
    HostSessionProgressEvent(:final step, :final authCode) => state.copyWith(
      progress: HostSessionProgress.completed(step),
      status: step == HostSessionProgressStep.advertising
          ? HostSessionStatus.hosting
          : HostSessionStatus.starting,
      // Null (the other steps) keeps the code already shown.
      authCode: authCode,
    ),
    HostSessionFailedEvent(:final step) => _failedAt(step),
    UnknownAdvertiserEvent() => state,
  };

  HostSessionState _failedAt(HostSessionProgressStep step) => state.copyWith(
    status: HostSessionStatus.failed,
    progress: HostSessionProgress.failed(step),
  );

  /// Only asks native to stop. `closed` is emitted when native reports
  /// `roomClosed` (see [_stateFor]), not when the call returns.
  Future<void> _onCloseRoomEvent(
    CloseRoomEvent event,
    Emitter<HostSessionState> emit,
  ) async {
    emit(state.copyWith(status: HostSessionStatus.closing));
    try {
      await _hostSessionRepository.stop();
    } catch (_) {
      emit(state.copyWith(status: HostSessionStatus.closeFailed));
    }
  }

  void _onPeerJoinedEvent(
    PeerJoinedEvent event,
    Emitter<HostSessionState> emit,
  ) {}

  void _onPeerSignalStrengthEvent(
    PeerSignalStrengthEvent event,
    Emitter<HostSessionState> emit,
  ) {}
}
