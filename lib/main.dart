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

Widget _withGap(Widget banner) =>
    Column(children: [banner, const SizedBox(height: 18)]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<BluetoothPermissionRepository>(
      create: (_) =>
          BluetoothPermissionRepositoryImpl(isAndroid: Platform.isAndroid),
      child: BlocProvider(
        create: (context) => BluetoothPermissionCubit(
          context.read<BluetoothPermissionRepository>(),
        ),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) =>
              BlocBuilder<BluetoothPermissionCubit, BluetoothPermissionState>(
                builder: (context, state) {
                  final isDenied =
                      state.status ==
                          BluetoothPermissionStatus.permissionDenied ||
                      state.status ==
                          BluetoothPermissionStatus.permissionPermanentlyDenied;
                  final isGranted =
                      state.status ==
                      BluetoothPermissionStatus.permissionGranted;
                  return SafeArea(
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        children: [
                          if (isDenied)
                            _withGap(
                              BluetoothBanner(
                                title: 'Bluetooth permission denied',
                                onTap: context
                                    .read<BluetoothPermissionCubit>()
                                    .request,
                              ),
                            )
                          else if (isGranted && state.isBluetoothOn == false)
                            _withGap(
                              BluetoothBanner(
                                title: 'Bluetooth is off',
                                onTap: context
                                    .read<BluetoothPermissionCubit>()
                                    .enableBluetooth,
                              ),
                            ),
                          Expanded(child: child!),
                        ],
                      ),
                    ),
                  );
                },
              ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
