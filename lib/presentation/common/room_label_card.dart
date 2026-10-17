import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RoomLabelCard extends StatelessWidget {
  const RoomLabelCard({
    super.key,
    required this.name,
    required this.code,
    required this.dimmed,
  });

  final String name;
  final String code;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: dimmed ? 0.45 : 1,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(name, style: tt.headlineMedium?.copyWith(fontSize: 26)),
                Text(
                  "·",
                  style: tt.headlineSmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: AppColors.primary300,
                  ),
                ),
                Text(
                  code,
                  style: tt.headlineMedium?.copyWith(
                    fontFamily: AppFonts.mono,
                    letterSpacing: 1.44,
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
          Text(
            "A 4-character code is added so rooms with the same name can be "
            "told apart. Share the whole label with people you want to join.",
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }
}
