enum BluetoothPermissionStatus {
  permissionDenied,
  permissionGranted,
  permissionPermanentlyDenied,
}

abstract class BluetoothPermissionRepository {
  /// Reads the current status without prompting.
  Future<BluetoothPermissionStatus> checkBluetoothPermission();

  /// Shows the system permission prompt, unless Bluetooth is off.
  Future<BluetoothPermissionStatus> requestBluetoothPermission();

  /// Reads the current status whether the bluetooth is off/on.
  Future<bool> checkBluetoothIsOn();

  /// Opens the system Bluetooth settings so the user can switch it on.
  Future<void> openBluetoothSettings();

  /// Opens system settings, for when the prompt can no longer be shown.
  Future<void> openSettings();
}
