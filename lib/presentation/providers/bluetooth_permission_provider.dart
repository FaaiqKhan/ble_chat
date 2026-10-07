import 'package:ble_chat/dependency_injection/bluetooth_provider.dart';
import 'package:ble_chat/domain/repository/bluetooth_permission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bluetoothPermissionControllerProvider =
    AsyncNotifierProvider<
      BluetoothPermissionController,
      BluetoothPermissionStatus
    >(BluetoothPermissionController.new);

/// Checks the Bluetooth permission on start and asks for it if missing.
class BluetoothPermissionController
    extends AsyncNotifier<BluetoothPermissionStatus> {
  BluetoothPermissionRepository get _repo =>
      ref.read(bluetoothPermissionProvider);

  @override
  Future<BluetoothPermissionStatus> build() async {
    final current = await _repo.checkBluetoothPermission();
    return current == BluetoothPermissionStatus.denied
        ? _repo.requestBluetoothPermission()
        : current;
  }

  /// Re-reads the status without prompting (e.g. after returning from
  /// system settings).
  Future<void> refresh() async {
    state = AsyncData(await _repo.checkBluetoothPermission());
  }

  /// Prompts for the permission, or opens system settings when the prompt
  /// can no longer be shown. When Bluetooth is off it only re-checks.
  Future<void> request() async {
    if (state.value == BluetoothPermissionStatus.bluetoothOff) {
      await refresh();
      return;
    }
    if (state.value == BluetoothPermissionStatus.permanentlyDenied) {
      await _repo.openSettings();
      return;
    }
    state = AsyncData(await _repo.requestBluetoothPermission());
  }
}
