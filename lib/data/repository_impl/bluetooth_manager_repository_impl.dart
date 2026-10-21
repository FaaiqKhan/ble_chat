import 'package:ble_chat/domain/repository/bluetooth_manager_repository.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManagerRepositoryImpl implements BluetoothManagerRepository {
  const BluetoothManagerRepositoryImpl({required this.isAndroid});

  final bool isAndroid;

  static const _channel = MethodChannel("bluetoothPermission");
  static const _stateEvents = EventChannel("bluetoothState/events");
  static const _stateMethods = MethodChannel("bluetoothState/methods");

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

  // Android 12 is API level 31.
  static const _androidSplitPermissionsSdk = 31;
  static int? _androidSdk;

  Future<int> _sdkInt() async => _androidSdk ??=
      await _channel.invokeMethod<int>('sdkInt') ?? _androidSplitPermissionsSdk;

  /// What the user must allow before scanning and advertising work:
  /// - Android 12+ splits Bluetooth into scan / connect / advertise.
  /// - Android 11 and older only return scan results to apps allowed to use
  ///   location (without it a scan finds nothing and reports no error).
  /// - iOS has a single Bluetooth permission.
  Future<List<Permission>> _permissions() async {
    if (!isAndroid) return [Permission.bluetooth];
    if (await _sdkInt() < _androidSplitPermissionsSdk) {
      return [Permission.locationWhenInUse];
    }
    return [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ];
  }

  @override
  Future<BluetoothPermissionStatus> checkBluetoothPermission() async {
    return _resolve([for (final p in await _permissions()) await p.status]);
  }

  @override
  Future<BluetoothPermissionStatus> requestBluetoothPermission() async {
    return _resolve((await (await _permissions()).request()).values);
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

  @override
  Future<bool> isBluetoothReady() => _stateMethods
      .invokeMethod("isBluetoothReady")
      .then((value) => value as bool)
      .catchError((_) => false);
}
