enum BluetoothPermissionStatus {
  granted,
  denied,
  permanentlyDenied,

  /// The Bluetooth radio is switched off; permission is not asked for.
  bluetoothOff,
}

abstract class BluetoothPermissionRepository {
  /// Reads the current status without prompting. Reports [bluetoothOff]
  /// before looking at the permission.
  Future<BluetoothPermissionStatus> checkBluetoothPermission();

  /// Shows the system permission prompt, unless Bluetooth is off.
  Future<BluetoothPermissionStatus> requestBluetoothPermission();

  /// Opens system settings, for when the prompt can no longer be shown.
  Future<void> openSettings();
}
