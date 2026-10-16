import 'dart:io';

import 'package:ble_chat/business_logic/bluetooth_manager/bluetooth_manager_cubit.dart';
import 'package:ble_chat/business_logic/bluetooth_manager/bluetooth_manager_state.dart';
import 'package:ble_chat/data/repository_impl/bluetooth_manager_repository_impl.dart';
import 'package:ble_chat/domain/repository/bluetooth_manager_repository.dart';
import 'package:ble_chat/presentation/common/bluetooth_banner.dart';
import 'package:ble_chat/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

Widget _bluetoothBannerHandler(
  BuildContext context,
  BluetoothPermissionState state,
) {
  String? title;
  VoidCallback? onTap;

  switch (state.status) {
    case BluetoothPermissionStatus.permissionGranted
        when (state.isBluetoothOn == false):
      title = "Bluetooth is off";
      onTap = context.read<BluetoothPermissionCubit>().enableBluetooth;
    case null:
    case BluetoothPermissionStatus.permissionGranted:
      return const SizedBox.shrink();
    case BluetoothPermissionStatus.permissionDenied:
    case BluetoothPermissionStatus.permissionPermanentlyDenied:
      title = "Bluetooth permission denied";
      onTap = context.read<BluetoothPermissionCubit>().request;
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: BluetoothBanner(title: title, onTap: onTap),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<BluetoothManagerRepository>(
      create: (_) =>
          BluetoothManagerRepositoryImpl(isAndroid: Platform.isAndroid),
      child: BlocProvider(
        create: (context) => BluetoothPermissionCubit(
          context.read<BluetoothManagerRepository>(),
        ),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) =>
              BlocBuilder<BluetoothPermissionCubit, BluetoothPermissionState>(
                builder: (context, state) => Column(
                  children: [
                    _bluetoothBannerHandler(context, state),
                    Expanded(child: child!),
                  ],
                ),
              ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
