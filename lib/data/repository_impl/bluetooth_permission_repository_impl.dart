import 'package:ble_chat/domain/repository/bluetooth_permission_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionRepositoryImpl
    implements BluetoothPermissionRepository {
  const BluetoothPermissionRepositoryImpl({required this.isAndroid});

  final bool isAndroid;

  // Android 12+ splits Bluetooth into scan / connect / advertise;
  // iOS has a single Bluetooth permission.
  List<Permission> get _permissions => isAndroid
      ? [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]
      : [Permission.bluetooth];

  @override
  Future<BluetoothPermissionStatus> checkBluetoothPermission() async {
    if (await _isBluetoothOff()) return BluetoothPermissionStatus.bluetoothOff;
    return _resolve([for (final p in _permissions) await p.status]);
  }

  @override
  Future<BluetoothPermissionStatus> requestBluetoothPermission() async {
    if (await _isBluetoothOff()) return BluetoothPermissionStatus.bluetoothOff;
    return _resolve((await _permissions.request()).values);
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<bool> _isBluetoothOff() async =>
      await Permission.bluetooth.serviceStatus != ServiceStatus.enabled;

  BluetoothPermissionStatus _resolve(Iterable<PermissionStatus> statuses) {
    if (statuses.every((s) => s.isGranted || s.isLimited)) {
      return BluetoothPermissionStatus.granted;
    }
    if (statuses.any((s) => s.isPermanentlyDenied || s.isRestricted)) {
      return BluetoothPermissionStatus.permanentlyDenied;
    }
    return BluetoothPermissionStatus.denied;
  }
}
