import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Rooms found by the scan. Rooms can share a name, so each shows its code
/// for the user to compare with the one their host gave them.
class FoundRoomList extends StatelessWidget {
  const FoundRoomList({super.key, required this.rooms, required this.scanning});

  final List<FoundRoom> rooms;

  /// The scan is still running, so more rooms may appear.
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              scanning
                  ? "SEARCHING · ${rooms.length} FOUND"
                  : "${rooms.length} ${rooms.length == 1 ? "ROOM" : "ROOMS"} FOUND",
              style: tt.labelSmall?.copyWith(letterSpacing: 0.88),
            ),
            if (scanning) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.palette.primaryFg,
                ),
              ),
            ],
          ],
        ),
        if (rooms.length > 1) ...[
          const SizedBox(height: 4),
          Text(
            "Same name? Pick the one with the code your host gave you.",
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            // Rooms are told apart by host address, so a row keeps its state
            // while the list grows.
            itemBuilder: (_, i) =>
                _FoundRoomCard(key: ValueKey(rooms[i].address), room: rooms[i]),
          ),
        ),
      ],
    );
  }
}

class _FoundRoomCard extends StatelessWidget {
  const _FoundRoomCard({super.key, required this.room});

  final FoundRoom room;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final (signalLabel, signalColor) = switch (bluetoothSignalOf(room.rssi)) {
      BluetoothSignal.good => ("Strong signal", palette.okFg),
      BluetoothSignal.weak => ("Weak signal", palette.warnFg),
      BluetoothSignal.poor => ("Very weak signal", palette.badFg),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline, width: 1.5),
        boxShadow: [palette.shadowCard],
      ),
      child: Column(
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
      ),
    );
  }
}
