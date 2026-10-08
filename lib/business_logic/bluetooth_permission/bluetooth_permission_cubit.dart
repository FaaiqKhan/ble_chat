import 'package:ble_chat/business_logic/bluetooth_permission/bluetooth_permission_state.dart';
import 'package:ble_chat/domain/repository/bluetooth_permission_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Checks the Bluetooth permission on start and asks for it if missing.
class BluetoothPermissionCubit extends Cubit<BluetoothPermissionState> {
  BluetoothPermissionCubit(this._repo)
    : super(const BluetoothPermissionState()) {
    _init();
  }

  final BluetoothPermissionRepository _repo;

  Future<void> _init() async {
    final current = await _repo.checkBluetoothPermission();
    final status = current == BluetoothPermissionStatus.permissionDenied
        ? await _repo.requestBluetoothPermission()
        : current;
    _emitStatus(status);
  }

  /// Sends the user to the system Bluetooth settings to switch it on.
  Future<void> enableBluetooth() => _repo.openBluetoothSettings();

  /// Re-reads the status without prompting (e.g. after returning from
  /// system settings).
  Future<void> refresh() async {
    _emitStatus(await _repo.checkBluetoothPermission());
  }

  /// Prompts for the permission, or opens system settings when the prompt
  /// can no longer be shown.
  Future<void> request() async {
    final current = state.status;
    if (current == BluetoothPermissionStatus.permissionPermanentlyDenied) {
      await _repo.openSettings();
      return;
    }
    _emitStatus(await _repo.requestBluetoothPermission());
  }

  void _emitStatus(BluetoothPermissionStatus status) {
    if (!isClosed) emit(BluetoothPermissionState(status: status));
  }
}
