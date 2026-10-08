import 'package:ble_chat/domain/repository/bluetooth_manager_repository.dart';

/// [status] is null until the first check finishes.
/// [isBluetoothOn] is null until the first radio state arrives.
class BluetoothPermissionState {
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
  bool operator ==(Object other) =>
      other is BluetoothPermissionState &&
      other.status == status &&
      other.isBluetoothOn == isBluetoothOn;

  @override
  int get hashCode => Object.hash(status, isBluetoothOn);
}
