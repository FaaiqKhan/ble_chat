import 'dart:async';

import 'package:ble_chat/business_logic/join_room/join_room_event.dart';
import 'package:ble_chat/business_logic/join_room/join_room_state.dart';
import 'package:ble_chat/domain/repository/join_room_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoinRoomBloc extends Bloc<JoinRoomEvent, JoinRoomState> {
  JoinRoomBloc(super.initialState, {required this._joinRoomRepository}) {
    on<ScanRoomEvent>(_onScanRoomEvent);
    on<StopScanRoomEvent>(_onStopScanRoomEvent);
    on<JoinRoom>(_onJoinRoom);
  }

  final JoinRoomRepository _joinRoomRepository;

  FutureOr<void> _onScanRoomEvent(
    ScanRoomEvent event,
    Emitter<JoinRoomState> emit,
  ) {
    emit(
      state.copyWith(roomName: event.roomName, status: JoinRoomStatus.scanning),
    );
    _joinRoomRepository.startScanning(event.roomName);
  }

  FutureOr<void> _onStopScanRoomEvent(
    StopScanRoomEvent event,
    Emitter<JoinRoomState> emit,
  ) async {
    emit(state.copyWith(status: JoinRoomStatus.idle));
    await _joinRoomRepository.stopScanning();
  }

  FutureOr<void> _onJoinRoom(JoinRoom event, Emitter<JoinRoomState> emit) {}
}
