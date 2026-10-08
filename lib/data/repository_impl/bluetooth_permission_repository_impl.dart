import 'package:ble_chat/domain/repository/bluetooth_permission_repository.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionRepositoryImpl
    implements BluetoothPermissionRepository {
  const BluetoothPermissionRepositoryImpl({required this.isAndroid});

  final bool isAndroid;

  static const _channel = MethodChannel('bluetoothPermission');

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
    return _resolve([for (final p in _permissions) await p.status]);
  }

  @override
  Future<BluetoothPermissionStatus> requestBluetoothPermission() async {
    return _resolve((await _permissions.request()).values);
  }

  @override
  Future<void> openBluetoothSettings() async {
    if (isAndroid) await _channel.invokeMethod<void>('openBluetoothSettings');
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  @override
  Future<bool> checkBluetoothIsOn() async =>
      await Permission.bluetooth.serviceStatus == ServiceStatus.enabled;

  BluetoothPermissionStatus _resolve(Iterable<PermissionStatus> statuses) {
    if (statuses.every((s) => s.isGranted || s.isLimited)) {
      return BluetoothPermissionStatus.permissionGranted;
    }
    if (statuses.any((s) => s.isPermanentlyDenied || s.isRestricted)) {
      return BluetoothPermissionStatus.permissionPermanentlyDenied;
    }
    return BluetoothPermissionStatus.permissionDenied;
  }
}
