import 'package:ble_chat/business_logic/host_session/host_session_event.dart';
import 'package:ble_chat/business_logic/host_session/host_session_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HostSessionBloc extends Bloc<HostSessionEvent, HostSessionState> {
  new(super.initialState) {
    on<StartHostingEvent>(_onStartHostingEvent);
    on<CloseRoomEvent>(_onCloseRoomEvent);
    on<PeerJoinedEvent>(_onPeerJoinedEvent);
    on<PeerSignalStrengthEvent>(_onPeerSignalStrengthEvent);
  }

  int get count => state.participants.length + 1;

  bool get isFull => count >= state.maxPeople;

  int get isOpen => (state.maxPeople - count).clamp(0, state.maxPeople);

  void _onStartHostingEvent(
    StartHostingEvent event,
    Emitter<HostSessionState> emit,
  ) {}

  void _onCloseRoomEvent(
    CloseRoomEvent event,
    Emitter<HostSessionState> emit,
  ) {}

  void _onPeerJoinedEvent(
    PeerJoinedEvent event,
    Emitter<HostSessionState> emit,
  ) {}

  void _onPeerSignalStrengthEvent(
    PeerSignalStrengthEvent event,
    Emitter<HostSessionState> emit,
  ) {}
}
