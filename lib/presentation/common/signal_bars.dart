import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Four signal-strength bars for a Bluetooth [rssi], coloured by quality
/// (good / weak / poor).
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.rssi, this.barWidth = 4});

  final int rssi;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lit = rssi >= -60
        ? 4
        : rssi >= -70
        ? 3
        : rssi >= -80
        ? 2
        : rssi >= -90
        ? 1
        : 0;
    final color = switch (bluetoothSignalOf(rssi)) {
      BluetoothSignal.good => palette.success,
      BluetoothSignal.weak => palette.warning,
      BluetoothSignal.poor => palette.error,
    };

    return SizedBox(
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: barWidth,
              height: 6.0 + i * 4,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
              decoration: BoxDecoration(
                color: i < lit ? color : Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}
