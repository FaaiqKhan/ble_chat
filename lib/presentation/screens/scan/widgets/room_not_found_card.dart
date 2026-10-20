import 'package:ble_chat/presentation/common/dashed_border.dart';
import 'package:ble_chat/presentation/common/icon_container.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shown when the scan ended without finding a room with the searched name.
class NotFoundRoomCard extends StatelessWidget {
  const NotFoundRoomCard({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      foregroundDecoration: DashedBorder(
        color: cs.outline,
        radius: AppRadius.lg,
      ),
      child: Column(
        // Wrap the content; a Column is as tall as its parent allows by default.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconContainer(
                iconData: Icons.search_off,
                iconColor: cs.onSurfaceVariant,
                backgroundColor: cs.surfaceContainerHigh,
              ),
              const SpacerBox(
                type: SpacerBoxType.horizontal,
                size: SpacerBoxSize.large,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "No room found",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "No room called “$query” nearby.",
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SpacerBox(
            type: SpacerBoxType.vertical,
            size: SpacerBoxSize.medium,
          ),
          Text(
            "· Check the spelling\n"
            "· Move closer to the host’s phone\n"
            "· Ask the host to check the room is open",
            style: tt.bodyMedium?.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}
