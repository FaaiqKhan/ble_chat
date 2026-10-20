import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:equatable/equatable.dart';

enum ScanSessionStatus { idle, scanning, scanned, joining, joined }

class ScanSessionState extends Equatable {
  const ScanSessionState({
    this.roomName = "",
    this.joined = 0,
    this.maxPeople = 0,
    this.signal = BluetoothSignal.poor,
    this.status = ScanSessionStatus.idle,
  });

  final String roomName;
  final int joined;
  final int maxPeople;
  final BluetoothSignal signal;
  final ScanSessionStatus status;

  ScanSessionState copyWith({
    String? roomName,
    int? joined,
    BluetoothSignal? signal,
    ScanSessionStatus? status,
  }) {
    return ScanSessionState(
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
