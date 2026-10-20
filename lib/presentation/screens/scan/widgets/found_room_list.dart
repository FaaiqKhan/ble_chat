import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Rooms found by the scan. Rooms can share a name, so each shows its code
/// for the user to compare with the one their host gave them.
class FoundRoomList extends StatelessWidget {
  const FoundRoomList({
    super.key,
    required this.rooms,
    required this.scanning,
    this.onSelect,
  });

  final List<FoundRoom> rooms;

  /// Called when a joinable room is tapped. Rooms that are gone or too weak
  /// ([FoundRoom.isJoinable]) ignore taps.
  final ValueChanged<FoundRoom>? onSelect;

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
            itemBuilder: (_, i) => _FoundRoomCard(
              key: ValueKey(rooms[i].address),
              room: rooms[i],
              onTap: onSelect == null ? null : () => onSelect!(rooms[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _FoundRoomCard extends StatelessWidget {
  const _FoundRoomCard({super.key, required this.room, this.onTap});

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
