import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MaxPeopleOption extends StatelessWidget {
  const MaxPeopleOption({
    super.key,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.ctaSoft : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.cta : cs.outline,
            width: 1.5,
          ),
        ),
        child: Text(
          "$value",
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: selected ? palette.ctaFg : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
