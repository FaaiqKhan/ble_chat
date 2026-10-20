import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class IconContainer extends StatelessWidget {
  const IconContainer({
    super.key,
    required this._iconData,
    required this._iconColor,
    required this._backgroundColor,
  });

  final Color _iconColor;
  final Color _backgroundColor;

  final IconData _iconData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(size: 24, color: _iconColor, _iconData),
    );
  }
}
