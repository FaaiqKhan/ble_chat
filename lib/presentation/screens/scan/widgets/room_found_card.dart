import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
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
        : room.isFull
        ? ("Room full", palette.badFg)
        : switch (bluetoothSignalOf(room.rssi)) {
            BluetoothSignal.good => ("Strong signal", palette.okFg),
            BluetoothSignal.weak => ("Weak signal", palette.warnFg),
            BluetoothSignal.poor => ("Very weak signal", palette.badFg),
          };

    final radius = BorderRadius.circular(AppRadius.lg);

    // Gone, full or too weak to connect: dimmed, and taps do nothing.
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
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.medium,
        ),
        Row(
          children: [
            SignalBars(rssi: room.rssi, barWidth: 5),
            const SpacerBox(
              type: SpacerBoxType.horizontal,
              size: SpacerBoxSize.medium,
            ),
            Expanded(
              child: Text(
                signalLabel,
                style: tt.bodySmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: signalColor,
                ),
              ),
            ),
            if (room.isFull)
              _FullTag(palette: palette)
            else
              Text(
                "${room.people} / ${room.maxPeople}",
                style: tt.bodyMedium?.copyWith(
                  fontFamily: AppFonts.mono,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "FULL" label shown instead of the people count once no spot is free.
class _FullTag extends StatelessWidget {
  const _FullTag({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        "FULL",
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: palette.badFg,
        ),
      ),
    );
  }
}
