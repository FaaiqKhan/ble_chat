import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:equatable/equatable.dart';

/// A room seen while scanning. Several rooms can share a [name]; the [code]
/// tells them apart.
class FoundRoom extends Equatable {
  const FoundRoom({
    required this.name,
    required this.code,
    required this.address,
    required this.rssi,
    required this.people,
    required this.maxPeople,
    this.isAvailable = true,
  });

  final String name;
  final String code;

  /// Bluetooth address of the host; needed to connect.
  final String address;
  final int rssi;

  /// People in the room, and how many it holds.
  final int people;
  final int maxPeople;

  /// Every spot is taken. Unknown capacity (0) never counts as full.
  bool get isFull => maxPeople > 0 && people >= maxPeople;

  /// False once the host hasn't been heard from for a while: it moved away or
  /// closed the room.
  final bool isAvailable;

  /// Whether the room can be joined: still around, a spot is free, and the
  /// signal isn't so weak that the connection would fail.
  bool get isJoinable =>
      isAvailable && !isFull && bluetoothSignalOf(rssi) != BluetoothSignal.poor;

  FoundRoom copyWith({int? rssi, int? people, bool? isAvailable}) => FoundRoom(
    name: name,
    code: code,
    address: address,
    rssi: rssi ?? this.rssi,
    people: people ?? this.people,
    maxPeople: maxPeople,
    isAvailable: isAvailable ?? this.isAvailable,
  );

  @override
  List<Object?> get props => [
    name,
    code,
    address,
    rssi,
    people,
    maxPeople,
    isAvailable,
  ];
}
