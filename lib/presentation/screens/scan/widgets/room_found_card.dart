import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class FoundRoomCard extends StatelessWidget {
  const FoundRoomCard({super.key, required this.room, this.onTap});

  final FoundRoom room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final (signalLabel, signalColor) = !room.isAvailable
        ? ("Not available", cs.onSurfaceVariant)
        : switch (bluetoothSignalOf(room.rssi)) {
            BluetoothSignal.good => ("Strong signal", palette.okFg),
            BluetoothSignal.weak => ("Weak signal", palette.warnFg),
            BluetoothSignal.poor => ("Very weak signal", palette.badFg),
          };

    final radius = BorderRadius.circular(AppRadius.lg);

    // Gone or too weak to connect: dimmed, and taps do nothing.
    return Opacity(
      opacity: room.isJoinable ? 1 : 0.5,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: cs.outline, width: 1.5),
        ),
        elevation: 0,
        child: InkWell(
          borderRadius: radius,
          onTap: room.isJoinable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _cardBody(context, signalLabel, signalColor),
          ),
        ),
      ),
    );
  }

  Widget _cardBody(
    BuildContext context,
    String signalLabel,
    Color signalColor,
  ) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.primaryBorder),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(room.name, style: tt.headlineSmall),
              Text(
                "·",
                style: tt.titleLarge?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: palette.primaryFg,
                ),
              ),
              Text(
                room.code,
                style: tt.titleLarge?.copyWith(
                  fontFamily: AppFonts.mono,
                  letterSpacing: 1.3,
                  color: palette.primaryFg,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SignalBars(rssi: room.rssi, barWidth: 5),
            const SizedBox(width: 8),
            Text(
              signalLabel,
              style: tt.bodySmall?.copyWith(
                fontFamily: AppFonts.mono,
                color: signalColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
