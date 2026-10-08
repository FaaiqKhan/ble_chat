import 'package:ble_chat/domain/repository/bluetooth_permission_repository.dart';

/// [status] is null until the first check finishes.
class BluetoothPermissionState {
  const BluetoothPermissionState({this.status});

  final BluetoothPermissionStatus? status;
}
