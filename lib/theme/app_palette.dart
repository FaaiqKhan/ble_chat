import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic design tokens that differ between light and dark themes
/// (the `[data-theme="dark"]` overrides in the Local Room design).
/// Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primarySoft,
    required this.primaryBorder,
    required this.primaryStrong,
    required this.primaryFg,
    required this.ctaSoft,
    required this.ctaFg,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.okFg,
    required this.warnFg,
    required this.badFg,
    required this.crown,
    required this.crownOn,
    required this.receivedBubble,
    required this.fullBg,
    required this.fullBorder,
    required this.toastBg,
    required this.scrim,
    required this.shadowCard,
  });

  /// Tinted brand surface (chips, icon tiles, room label).
  final Color primarySoft;
  final Color primaryBorder;
  final Color primaryStrong;

  /// Brand purple used as text/icon colour.
  final Color primaryFg;
  final Color ctaSoft;
  final Color ctaFg;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;

  /// Text colours for signal quality: good / weak / poor.
  final Color okFg;
  final Color warnFg;
  final Color badFg;

  /// Host badge.
  final Color crown;
  final Color crownOn;

  final Color receivedBubble;
  final Color fullBg;
  final Color fullBorder;
  final Color toastBg;
  final Color scrim;
  final BoxShadow shadowCard;

  static const light = AppPalette(
    primarySoft: AppColors.primary050,
    primaryBorder: AppColors.primary200,
    primaryStrong: AppColors.primary600,
    primaryFg: AppColors.primary,
    ctaSoft: AppColors.cta050,
    ctaFg: AppColors.cta,
    success: AppColors.success,
    successSoft: AppColors.success050,
    warning: AppColors.warning,
    warningSoft: AppColors.warning050,
    error: AppColors.error,
    errorSoft: AppColors.error050,
    okFg: AppColors.success,
    warnFg: AppColors.warning,
    badFg: AppColors.error,
    crown: AppColors.crown,
    crownOn: AppColors.darkBg,
    receivedBubble: AppColors.surface2,
    fullBg: AppColors.darkBg,
    fullBorder: AppColors.darkBg,
    toastBg: AppColors.darkBg,
    scrim: AppColors.scrim,
    shadowCard: AppColors.shadow1,
  );

  static const dark = AppPalette(
    primarySoft: AppColors.darkPrimary050,
    primaryBorder: AppColors.darkPrimary200,
    primaryStrong: AppColors.darkPrimary600,
    primaryFg: AppColors.darkPrimaryFg,
    ctaSoft: AppColors.darkCta050,
    ctaFg: AppColors.darkCtaFg,
    success: AppColors.darkSuccess,
    successSoft: AppColors.darkSuccess050,
    warning: AppColors.darkWarning,
    warningSoft: AppColors.darkWarning050,
    error: AppColors.darkError,
    errorSoft: AppColors.darkError050,
    okFg: AppColors.darkOkFg,
    warnFg: AppColors.darkWarning,
    badFg: AppColors.darkBadFg,
    crown: AppColors.accent,
    crownOn: AppColors.darkBg,
    receivedBubble: AppColors.darkReceivedBubble,
    fullBg: AppColors.darkBorder,
    fullBorder: AppColors.darkBorderStrong,
    toastBg: AppColors.darkBorder,
    scrim: AppColors.darkScrim,
    shadowCard: AppColors.shadow1Dark,
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
