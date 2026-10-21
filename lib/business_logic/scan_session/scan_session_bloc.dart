import 'dart:async';

import 'package:ble_chat/business_logic/scan_session/scan_session_event.dart';
import 'package:ble_chat/business_logic/scan_session/scan_session_state.dart';
import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/domain/entities/scanner_event.dart';
import 'package:ble_chat/domain/repository/scan_session_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanSessionBloc extends Bloc<ScanSessionEvent, ScanSessionState> {
  ScanSessionBloc(super.initialState, {required this._scanSessionRepository}) {
    on<ScanRoomEvent>(_onScanRoomEvent);
    on<StopScanRoomEvent>(_onStopScanRoomEvent);
    on<ScanEventReceived>(_onScanEventReceived);
    on<StaleRoomsCheck>(_onStaleRoomsCheck);
  }

  final ScanSessionRepository _scanSessionRepository;

  /// How much of each new RSSI reading is mixed into the running value. Raw
  /// readings jump by ~10 dBm; a low weight keeps the average steady.
  static const _smoothing = 0.3;

  /// Running (smoothed) RSSI per host address. Kept here, not in the state:
  /// the state only changes when the bars would, so it can't hold this value.
  final Map<String, double> _smoothedRssi = {};

  /// A host not heard from for this long is treated as gone. Native reports
  /// each host about once a second, so this allows several misses.
  static const _staleAfter = Duration(seconds: 5);

  /// When each host (by address) was last heard from.
  final Map<String, DateTime> _lastSeen = {};

  /// Checks for gone hosts once a second while a scan runs.
  Timer? _staleTimer;

  /// Listens to native for the current scan only. Replaced on every new scan
  /// and cancelled when the scan ends, so scans never overlap.
  StreamSubscription<ScannerEvent>? _scanSubscription;

  Future<void> _onScanRoomEvent(
    ScanRoomEvent event,
    Emitter<ScanSessionState> emit,
  ) async {
    await _scanSubscription?.cancel();
    _smoothedRssi.clear();
    _lastSeen.clear();
    _staleTimer?.cancel();
    _staleTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(StaleRoomsCheck()),
    );
    emit(
      ScanSessionState(query: event.query, status: ScanSessionStatus.scanning),
    );

    // Listen before asking native to start, so no early event is missed.
    // Each native message is turned into a bloc event: handlers are the only
    // place that emits, which keeps state changes in one order.
    _scanSubscription = _scanSessionRepository.scanSessionEvents().listen(
      (native) => add(ScanEventReceived(native)),
    );
    try {
      await _scanSessionRepository.startScanning(event.query);
    } catch (_) {
      emit(state.copyWith(status: ScanSessionStatus.failed));
      _staleTimer?.cancel();
      await _scanSubscription?.cancel();
    }
  }

  Future<void> _onStopScanRoomEvent(
    StopScanRoomEvent event,
    Emitter<ScanSessionState> emit,
  ) async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _staleTimer?.cancel();
    emit(const ScanSessionState());
    await _scanSessionRepository.stopScanning();
  }

  Future<void> _onScanEventReceived(
    ScanEventReceived event,
    Emitter<ScanSessionState> emit,
  ) async {
    final next = _stateFor(event.event);
    emit(next);
    // Found, timed out or failed: this scan is over, stop listening.
    if (next.status != ScanSessionStatus.scanning) {
      // Nothing is heard any more, so the rooms keep how they looked.
      _staleTimer?.cancel();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  /// Marks rooms not heard from for [_staleAfter] as unavailable. Emits only
  /// if something changed.
  void _onStaleRoomsCheck(
    StaleRoomsCheck event,
    Emitter<ScanSessionState> emit,
  ) {
    if (state.status != ScanSessionStatus.scanning) return;
    final now = DateTime.now();
    emit(
      state.copyWith(
        rooms: [
          for (final room in state.rooms)
            room.copyWith(
              isAvailable:
                  now.difference(_lastSeen[room.address] ?? now) < _staleAfter,
            ),
        ],
      ),
    );
  }

  /// Turns one native report into the next state. Pure: it reads [state] and
  /// returns a new one, it never emits or calls native.
  ScanSessionState _stateFor(ScannerEvent event) => switch (event) {
    // A late message from a scan that was cancelled or already finished must
    // not change what the user sees.
    _ when state.status != ScanSessionStatus.scanning => state,
    ScannerStartedEvent() => state,
    ScannerResultEvent() => state.copyWith(rooms: _withRoom(event)),
    // The scan window is over: whatever was collected is the answer.
    ScannerTimeoutEvent() => state.copyWith(
      status: state.rooms.isEmpty
          ? ScanSessionStatus.notFound
          : ScanSessionStatus.scanned,
    ),
    ScannerFailedEvent() => state.copyWith(
      status: ScanSessionStatus.failed,
      errorMessage: event.message,
    ),
    UnknownScannerEvent() => state,
  };

  /// Adds the room, or updates its signal if this host is already listed.
  ///
  /// The reading is smoothed first, and the listed signal only changes when
  /// the bars (count or colour) would look different. Otherwise the same list
  /// is returned, the state is equal, and nothing is emitted or rebuilt.
  List<FoundRoom> _withRoom(ScannerResultEvent event) {
    final previous = _smoothedRssi[event.address];
    final smoothed = previous == null
        ? event.rssi.toDouble()
        : previous + _smoothing * (event.rssi - previous);
    _smoothedRssi[event.address] = smoothed;
    _lastSeen[event.address] = DateTime.now();
    final rssi = smoothed.round();

    final i = state.rooms.indexWhere((r) => r.address == event.address);
    if (i < 0) {
      return [
        ...state.rooms,
        FoundRoom(
          name: event.roomName,
          code: event.roomCode,
          address: event.address,
          rssi: rssi,
          people: event.people,
          maxPeople: event.maxPeople,
        ),
      ];
    }

    // Heard again, so it is back even if its bars stay the same. A new people
    // count always shows: it can make the room full.
    final shown = state.rooms[i];
    if (shown.isAvailable &&
        shown.people == event.people &&
        !signalLooksDifferent(shown.rssi, rssi)) {
      return state.rooms;
    }

    final rooms = [...state.rooms];
    rooms[i] = shown.copyWith(
      rssi: rssi,
      people: event.people,
      isAvailable: true,
    );
    return rooms;
  }

  @override
  Future<void> close() async {
    _staleTimer?.cancel();
    await _scanSubscription?.cancel();
    return super.close();
  }
}
