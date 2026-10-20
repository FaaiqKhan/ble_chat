import 'dart:async';

import 'package:ble_chat/business_logic/scan_session/scan_session_event.dart';
import 'package:ble_chat/business_logic/scan_session/scan_session_state.dart';
import 'package:ble_chat/domain/repository/join_room_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanSessionBloc extends Bloc<ScanSessionEvent, ScanSessionState> {
  ScanSessionBloc(super.initialState, {required this._scanRoomRepository}) {
    on<ScanRoomEvent>(_onScanRoomEvent);
    on<StopScanRoomEvent>(_onStopScanRoomEvent);
  }

  final ScanRoomRepository _scanRoomRepository;

  FutureOr<void> _onScanRoomEvent(
    ScanRoomEvent event,
    Emitter<ScanSessionState> emit,
  ) {
    emit(
      state.copyWith(
        roomName: event.roomName,
        status: ScanSessionStatus.scanning,
      ),
    );
    _scanRoomRepository.startScanning(
      name: event.roomName,
      code: event.roomCode,
    );
  }

  FutureOr<void> _onStopScanRoomEvent(
    StopScanRoomEvent event,
    Emitter<ScanSessionState> emit,
  ) async {
    emit(state.copyWith(status: ScanSessionStatus.idle));
    await _scanRoomRepository.stopScanning();
  }
}
