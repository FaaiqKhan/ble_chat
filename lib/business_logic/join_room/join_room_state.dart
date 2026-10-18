import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:equatable/equatable.dart';

enum JoinRoomStatus { idle, scanning, scanned, joining, joined }

class JoinRoomState extends Equatable {
  const JoinRoomState({
    this.roomName = "",
    this.joined = 0,
    this.maxPeople = 0,
    this.signal = BluetoothSignal.poor,
    this.status = JoinRoomStatus.idle,
  });

  final String roomName;
  final int joined;
  final int maxPeople;
  final BluetoothSignal signal;
  final JoinRoomStatus status;

  JoinRoomState copyWith({
    String? roomName,
    int? joined,
    BluetoothSignal? signal,
    JoinRoomStatus? status,
  }) {
    return JoinRoomState(
      roomName: roomName ?? this.roomName,
      joined: joined ?? this.joined,
      maxPeople: maxPeople,
      signal: signal ?? this.signal,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [roomName, joined, maxPeople, signal, status];
}
