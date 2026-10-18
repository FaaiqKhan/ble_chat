import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

class ClosingRoomBanner extends StatelessWidget {
  const ClosingRoomBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final palette = context.palette;
    final radius = BorderRadius.circular(14);

    return Material(
      textStyle: tt.titleLarge?.copyWith(color: palette.warning),
      color: palette.warningSoft,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: palette.warning, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Row(
          children: [
            CircularProgressIndicator(
              color: palette.warning,
              strokeWidth: 3,
              constraints: BoxConstraints(
                minWidth: 22,
                maxWidth: 22,
                minHeight: 22,
                maxHeight: 22,
              ),
            ),
            const SpacerBox(
              type: SpacerBoxType.horizontal,
              size: SpacerBoxSize.large,
            ),
            Text("Closing your room..."),
          ],
        ),
      ),
    );
  }
}
