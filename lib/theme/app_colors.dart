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
  static const crown = Color(0xFFC79A00); // host badge on light

  // Status
  static const success = Color(0xFF12D18E);
  static const success050 = Color(0xFFF1FDF5);
  static const warning = Color(0xFFFACC15);
  static const warning050 = Color(0xFFFFFCEB);
  static const error = Color(0xFFF75555);
  static const error050 = Color(0xFFFFF7F8);

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

  static const scrim = Color(0x66000000);

  static const onPrimary = Color(0xFFFFFFFF);

  static const primaryGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primary300],
  );

  // Dark-theme brand overrides
  static const darkPrimary050 = Color(0xFF272250);
  static const darkPrimary200 = Color(0xFF4B3F9E);
  static const darkPrimary600 = Color(0xFFB3A5FF);
  static const darkPrimaryFg = Color(0xFFA592FF);
  static const darkCta050 = Color(0xFF1B2740);
  static const darkCtaFg = Color(0xFF6B9DFF);

  // Dark-theme status overrides
  static const darkSuccess = Color(0xFF27C99A);
  static const darkSuccess050 = Color(0xFF12312A);
  static const darkWarning = Color(0xFFF2C94C);
  static const darkWarning050 = Color(0xFF342D12);
  static const darkError = Color(0xFFF26B6B);
  static const darkError050 = Color(0xFF3A2227);
  static const darkOkFg = Color(0xFF34D3A0);
  static const darkBadFg = Color(0xFFFF8A8A);
  static const darkReceivedBubble = Color(0xFF2B303C);
  static const darkScrim = Color(0x99000000);

  // Shadows
  static const shadowPrimary = BoxShadow(
    color: Color(0x476949FF),
    offset: Offset(0, 10),
    blurRadius: 24,
  );
  static const shadow1 = BoxShadow(
    color: Color(0x14181A20),
    offset: Offset(0, 4),
    blurRadius: 16,
  );
  static const shadow1Dark = BoxShadow(
    color: Color(0x59000000),
    offset: Offset(0, 4),
    blurRadius: 16,
  );

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
