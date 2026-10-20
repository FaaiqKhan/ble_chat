import 'package:equatable/equatable.dart';

/// A room seen while scanning. Several rooms can share a [name]; the [code]
/// tells them apart.
class FoundRoom extends Equatable {
  const FoundRoom({
    required this.name,
    required this.code,
    required this.address,
    required this.rssi,
  });

  final String name;
  final String code;

  /// Bluetooth address of the host; needed to connect.
  final String address;
  final int rssi;

  FoundRoom copyWith({int? rssi}) => FoundRoom(
    name: name,
    code: code,
    address: address,
    rssi: rssi ?? this.rssi,
  );

  @override
  List<Object?> get props => [name, code, address, rssi];
}
