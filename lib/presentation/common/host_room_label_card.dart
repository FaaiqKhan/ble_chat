import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HostRoomLabelCard extends StatelessWidget {
  const HostRoomLabelCard({super.key, required this.name, required this.code});

  final String name;
  final String code;

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
          Text(
            "ROOM LABEL · SHARE THIS",
            style: tt.labelSmall?.copyWith(
              fontFamily: AppFonts.mono,
              fontSize: 10,
              letterSpacing: 0.8,
              color: palette.primaryStrong,
            ),
          ),
          const SpacerBox(
            type: SpacerBoxType.vertical,
            size: SpacerBoxSize.small,
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(name, style: tt.headlineMedium?.copyWith(fontSize: 32)),
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
        ],
      ),
    );
  }
}
