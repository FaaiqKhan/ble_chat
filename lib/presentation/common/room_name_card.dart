import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RoomNameCard extends StatelessWidget {
  const RoomNameCard({super.key, required this._name, required this._code});

  final String _name;

  /// This is a code used to distinguish between rooms with the same name
  /// It's not an authentication code
  final String _code;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return Container(
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
          Text(_name, style: tt.headlineSmall),
          Text(
            "·",
            style: tt.titleLarge?.copyWith(
              fontFamily: AppFonts.mono,
              color: palette.primaryFg,
            ),
          ),
          Text(
            _code,
            style: tt.titleLarge?.copyWith(
              fontFamily: AppFonts.mono,
              letterSpacing: 1.3,
              color: palette.primaryFg,
            ),
          ),
        ],
      ),
    );
  }
}
