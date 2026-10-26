import 'dart:async';

import 'package:ble_chat/business_logic/connect_session/connect_session_event.dart';
import 'package:ble_chat/business_logic/connect_session/connect_session_state.dart';
import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/domain/entities/connect_event.dart';
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
    on<ConnectEventReceived>(_onConnectEventReceived);
  }

  final ConnectSessionRepository _connectSessionRepository;

  /// How much of each new reading is mixed into the running value. Raw readings
  /// jump by ~10 dBm; a low weight keeps the average steady.
  static const _smoothing = 0.3;

  /// Running (smoothed) signal strength. Kept here, not in the state: the state only
  /// changes when the bars would.
  double? _smoothedRssi;

  /// Listens to native for this connection. Cancelled as soon as nothing more is
  /// wanted from it (the attempt failed, the link was lost, or the user left), so it
  /// never outlives the connection.
  StreamSubscription<ConnectEvent>? _subscription;

  Future<void> _onConnectChatSessionEvent(
    ConnectChatSessionEvent event,
    Emitter<ConnectSessionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ConnectSessionStatus.connecting,
        guestName: event.guestName,
        progress: ConnectSessionProgress.initial(),
      ),
    );

    // Listen before asking native to start, so no early event is missed. Each native
    // message becomes a bloc event, so only handlers emit.
    _smoothedRssi = null;
    await _subscription?.cancel();
    _subscription = _connectSessionRepository.connectSessionEvents().listen(
      (native) => add(ConnectEventReceived(native)),
    );
    try {
      await _connectSessionRepository.connect(state.room, state.authCode);
    } catch (_) {
      emit(_failedAt(ConnectSessionProgressStep.connect));
      await _closeSubscription();
    }
  }

  Future<void> _onConnectEventReceived(
    ConnectEventReceived event,
    Emitter<ConnectSessionState> emit,
  ) async {
    final next = _stateFor(event.event);
    emit(next);
    // Failed or lost: native has nothing more to say about this connection.
    if (next.status == ConnectSessionStatus.failed ||
        next.status == ConnectSessionStatus.lost) {
      await _closeSubscription();
    }
  }

  Future<void> _closeSubscription() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Turns one native report into the next state. Pure: it reads [state] and
  /// returns a new one, it never emits or calls native.
  ConnectSessionState _stateFor(ConnectEvent event) => switch (event) {
    // Once joining has ended (failed, left, or lost) late reports are noise.
    _
        when state.status != ConnectSessionStatus.connecting &&
            state.status != ConnectSessionStatus.connected =>
      state,
    ConnectStepDoneEvent(:final step) => state.copyWith(
      progress: ConnectSessionProgress.completed(step),
      step: step,
      // The last step done means the room is open for chat.
      status: step == ConnectSessionProgressStep.join
          ? ConnectSessionStatus.connected
          : ConnectSessionStatus.connecting,
    ),
    ConnectFailedEvent() => _failedAt(
      event.step,
      code: event.code,
      message: event.message,
    ),
    ConnectHostNameEvent(:final name) => state.copyWith(hostName: name),
    ConnectRssiEvent(:final rssi) => _withRssi(rssi),
    // Dropped while joining: that step didn't finish. Dropped in the room: lost.
    ConnectDisconnectedEvent() =>
      state.status == ConnectSessionStatus.connected
          ? state.copyWith(status: ConnectSessionStatus.lost)
          : _failedAt(state.step, code: "connection_failed"),
    UnknownConnectEvent() => state,
  };

  /// Smooths the reading and only changes the state when the bars (count or colour)
  /// would look different; otherwise the same state is returned and nothing rebuilds.
  ConnectSessionState _withRssi(int rssi) {
    final previous = _smoothedRssi ?? state.signal.toDouble();
    final smoothed = previous + _smoothing * (rssi - previous);
    _smoothedRssi = smoothed;
    final shown = smoothed.round();
    return signalLooksDifferent(state.signal, shown)
        ? state.copyWith(rssi: shown)
        : state;
  }

  ConnectSessionState _failedAt(
    ConnectSessionProgressStep step, {
    String? code,
    String? message,
  }) => state.copyWith(
    status: ConnectSessionStatus.failed,
    step: step,
    progress: ConnectSessionProgress.failed(step),
    errorCode: code,
    errorMessage: message,
  );

  Future<void> _onDisconnectChatSessionEvent(
    DisconnectChatSessionEvent event,
    Emitter<ConnectSessionState> emit,
  ) async {
    // The user is leaving: stop listening first so a late report from native
    // can't change the state while it winds down.
    await _closeSubscription();
    emit(state.copyWith(status: ConnectSessionStatus.disconnecting));
    try {
      await _connectSessionRepository.disconnect();
    } finally {
      emit(state.copyWith(status: ConnectSessionStatus.disconnected));
    }
  }

  @override
  Future<void> close() async {
    await _closeSubscription();
    return super.close();
  }
}
