import 'dart:async';

import 'package:ble_chat/business_logic/scan_session/scan_session_event.dart';
import 'package:ble_chat/business_logic/scan_session/scan_session_state.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/domain/entities/scanner_event.dart';
import 'package:ble_chat/domain/repository/session_session_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanSessionBloc extends Bloc<ScanSessionEvent, ScanSessionState> {
  ScanSessionBloc(super.initialState, {required this._scanSessionRepository}) {
    on<ScanRoomEvent>(_onScanRoomEvent);
    on<StopScanRoomEvent>(_onStopScanRoomEvent);
    on<ScanEventReceived>(_onScanEventReceived);
  }

  final ScanSessionRepository _scanSessionRepository;

  /// Listens to native for the current scan only. Replaced on every new scan
  /// and cancelled when the scan ends, so scans never overlap.
  StreamSubscription<ScannerEvent>? _scanSubscription;

  Future<void> _onScanRoomEvent(
    ScanRoomEvent event,
    Emitter<ScanSessionState> emit,
  ) async {
    await _scanSubscription?.cancel();
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
      await _scanSubscription?.cancel();
    }
  }

  Future<void> _onStopScanRoomEvent(
    StopScanRoomEvent event,
    Emitter<ScanSessionState> emit,
  ) async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
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
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
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

  /// Adds the room, or refreshes its signal if this host is already listed.
  List<FoundRoom> _withRoom(ScannerResultEvent event) {
    final room = FoundRoom(
      name: event.roomName,
      code: event.roomCode,
      address: event.address,
      rssi: event.rssi,
    );
    final i = state.rooms.indexWhere((r) => r.address == room.address);
    if (i < 0) return [...state.rooms, room];

    final rooms = [...state.rooms];
    rooms[i] = rooms[i].copyWith(rssi: room.rssi);
    return rooms;
  }

  @override
  Future<void> close() async {
    await _scanSubscription?.cancel();
    return super.close();
  }
}
