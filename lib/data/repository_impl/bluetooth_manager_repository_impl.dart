import 'package:ble_chat/domain/repository/bluetooth_manager_repository.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionRepositoryImpl
    implements BluetoothPermissionRepository {
  const BluetoothPermissionRepositoryImpl({required this.isAndroid});

  final bool isAndroid;

  static const _channel = MethodChannel('bluetoothPermission');
  static const _stateEvents = EventChannel('bluetoothState/events');

  @override
  Stream<bool> watchBluetoothIsOn() => _stateEvents
      .receiveBroadcastStream()
      .cast<String>()
      .where((s) => s != 'unknown')
      .map((s) => s == 'on' || s == 'turningOn')
      .distinct();

  BluetoothPermissionStatus _resolve(Iterable<PermissionStatus> statuses) {
    if (statuses.every((s) => s.isGranted || s.isLimited)) {
      return BluetoothPermissionStatus.permissionGranted;
    }
    if (statuses.any((s) => s.isPermanentlyDenied || s.isRestricted)) {
      return BluetoothPermissionStatus.permissionPermanentlyDenied;
    }
    return BluetoothPermissionStatus.permissionDenied;
  }

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
    // iOS has no public link to the Bluetooth page, so open the app's settings.
    if (isAndroid) {
      await _channel.invokeMethod<void>('openBluetoothSettings');
    } else {
      await openAppSettings();
    }
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
