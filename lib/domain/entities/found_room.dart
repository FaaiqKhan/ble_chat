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
    this.isAvailable = true,
  });

  final String name;
  final String code;

  /// Bluetooth address of the host; needed to connect.
  final String address;
  final int rssi;

  /// False once the host hasn't been heard from for a while: it moved away or
  /// closed the room.
  final bool isAvailable;

  /// Whether the room can be joined: still around, and the signal isn't so
  /// weak that the connection would fail.
  bool get isJoinable =>
      isAvailable && bluetoothSignalOf(rssi) != BluetoothSignal.poor;

  FoundRoom copyWith({int? rssi, bool? isAvailable}) => FoundRoom(
    name: name,
    code: code,
    address: address,
    rssi: rssi ?? this.rssi,
    isAvailable: isAvailable ?? this.isAvailable,
  );

  @override
  List<Object?> get props => [name, code, address, rssi, isAvailable];
}
