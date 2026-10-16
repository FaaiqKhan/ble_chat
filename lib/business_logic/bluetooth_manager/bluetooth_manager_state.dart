import 'package:ble_chat/domain/repository/bluetooth_manager_repository.dart';
import 'package:equatable/equatable.dart';

/// [status] is null until the first check finishes.
/// [isBluetoothOn] is null until the first radio state arrives.
class BluetoothPermissionState extends Equatable {
  const BluetoothPermissionState({this.status, this.isBluetoothOn});

  final BluetoothPermissionStatus? status;
  final bool? isBluetoothOn;

  BluetoothPermissionState copyWith({
    BluetoothPermissionStatus? status,
    bool? isBluetoothOn,
  }) => BluetoothPermissionState(
    status: status ?? this.status,
    isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
  );

  @override
  List<Object?> get props => [status, isBluetoothOn];
}
