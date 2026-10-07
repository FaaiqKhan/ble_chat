import 'dart:io';

import 'package:ble_chat/data/repository_impl/bluetooth_permission_repository_impl.dart';
import 'package:ble_chat/domain/repository/bluetooth_permission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bluetoothPermissionProvider = Provider<BluetoothPermissionRepository>(
  (ref) => BluetoothPermissionRepositoryImpl(isAndroid: Platform.isAndroid),
);
