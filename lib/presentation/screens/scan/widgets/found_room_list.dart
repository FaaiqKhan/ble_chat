import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/scan/widgets/room_found_card.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Rooms found by the scan. Rooms can share a name, so each shows its code
/// for the user to compare with the one their host gave them.
class FoundRoomList extends StatelessWidget {
  const FoundRoomList({
    super.key,
    required this.rooms,
    required this.isScanning,
    required this.query,
    this.onVerify,
    this.verifyingAddress,
    this.wrongCodeAddress,
    this.onCodeChanged,
  });

  final List<FoundRoom> rooms;

  /// Called with the room and the 6 digits typed for it when Verify & Join is
  /// pressed. Rooms that are gone, full or too weak ([FoundRoom.isJoinable])
  /// can't be opened.
  final void Function(FoundRoom room, String code)? onVerify;

  /// Address of the room whose code is being checked, if any.
  final String? verifyingAddress;

  /// Address of the room whose last code was wrong, if any.
  final String? wrongCodeAddress;

  /// Called as the user types a code, so a shown error can be cleared.
  final VoidCallback? onCodeChanged;

  /// The scan is still running, so more rooms may appear.
  final bool isScanning;

  final String query;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isScanning)
          Row(
            children: [
              Text(
                "SEARCHING · ${rooms.length} FOUND",
                style: tt.labelSmall?.copyWith(letterSpacing: 0.88),
              ),
              const SpacerBox(
                type: SpacerBoxType.horizontal,
                size: SpacerBoxSize.medium,
              ),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.palette.primaryFg,
                ),
              ),
            ],
          ),
        if (isScanning)
          const SpacerBox(
            type: SpacerBoxType.vertical,
            size: SpacerBoxSize.medium,
          ),
        if (rooms.length == 1) ...[
          Text("${rooms.length} rooms match “$query”", style: tt.titleLarge),
          const SpacerBox(
            type: SpacerBoxType.vertical,
            size: SpacerBoxSize.small,
          ),
          Text(
            "Same name? Pick the one with the code your host gave you.",
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.medium,
        ),
        Expanded(
          child: ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const SpacerBox(
              type: SpacerBoxType.vertical,
              size: SpacerBoxSize.medium,
            ),
            // Rooms are told apart by host address, so a row keeps its state
            // while the list grows.
            itemBuilder: (_, i) => FoundRoomCard(
              key: ValueKey(rooms[i].address),
              room: rooms[i],
              onVerify: onVerify == null
                  ? null
                  : (code) => onVerify!(rooms[i], code),
            ),
          ),
        ),
      ],
    );
  }
}
