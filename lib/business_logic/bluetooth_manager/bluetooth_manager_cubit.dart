import 'dart:async';

import 'package:ble_chat/business_logic/bluetooth_manager/bluetooth_manager_state.dart';
import 'package:ble_chat/domain/repository/bluetooth_manager_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Checks the Bluetooth permission on start and asks for it if missing, and
/// tracks whether the Bluetooth radio is on once permission is granted.
class BluetoothPermissionCubit extends Cubit<BluetoothPermissionState> {
  BluetoothPermissionCubit(this._repo)
    : super(const BluetoothPermissionState()) {
    _init();
  }

  final BluetoothPermissionRepository _repo;
  StreamSubscription<bool>? _bluetoothSub;

  @override
  Future<void> close() {
    _bluetoothSub?.cancel();
    return super.close();
  }

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

  /// The radio state is only watched while permission is granted, as it
  /// can't be read reliably without it (notably on iOS).
  void _emitStatus(BluetoothPermissionStatus status) {
    if (status == BluetoothPermissionStatus.permissionGranted) {
      _bluetoothSub ??= _repo.watchBluetoothIsOn().listen(
        (isOn) => _emit(state.copyWith(isBluetoothOn: isOn)),
      );
      _emit(state.copyWith(status: status));
    } else {
      _bluetoothSub?.cancel();
      _bluetoothSub = null;
      _emit(BluetoothPermissionState(status: status));
    }
  }

  void _emit(BluetoothPermissionState next) {
    if (!isClosed) emit(next);
  }
}
