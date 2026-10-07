import 'package:flutter/material.dart';

/// Design tokens from the Local Room design (colors_and_type.css).
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6949FF);
  static const primary600 = Color(0xFF543ACC);
  static const primary300 = Color(0xFF876DFF);
  static const primary200 = Color(0xFFC3B6FF);
  static const primary050 = Color(0xFFF4F1FF);

  static const cta = Color(0xFF246BFD);
  static const cta600 = Color(0xFF3779FF);
  static const cta050 = Color(0xFFF6F9FF);

  static const accent = Color(0xFFFACC15);

  // Status
  static const success = Color(0xFF12D18E);
  static const warning = Color(0xFFFACC15);
  static const error = Color(0xFFF75555);

  // Light neutrals
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFAFAFA);
  static const surface2 = Color(0xFFF5F5F5);
  static const border = Color(0xFFEEEEEE);
  static const borderStrong = Color(0xFFE0E0E0);
  static const fg1 = Color(0xFF212121);
  static const fg2 = Color(0xFF424242);
  static const fg3 = Color(0xFF616161);
  static const fg4 = Color(0xFF9E9E9E);

  // Dark neutrals
  static const darkBg = Color(0xFF181A20);
  static const darkSurface = Color(0xFF1F222A);
  static const darkSurface2 = Color(0xFF262A35);
  static const darkBorder = Color(0xFF35383F);
  static const darkBorderStrong = Color(0xFF4A4D54);
  static const darkFg1 = Color(0xFFFFFFFF);
  static const darkFg2 = Color(0xFFEEEEEE);
  static const darkFg3 = Color(0xFFBDBDBD);
  static const darkFg4 = Color(0xFF757575);
}
