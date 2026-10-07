import 'package:ble_chat/presentation/common/bluetooth_banner.dart';
import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onHost, this.onJoin});

  final VoidCallback? onHost;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BluetoothBanner(title: 'Bluetooth is off', onTap: () {}),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WORKS WITHOUT INTERNET',
                        style: monoStyle(
                          size: 11,
                          weight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ).copyWith(letterSpacing: 11 * 0.08),
                      ),
                      const SizedBox(height: 8),
                      Text('Local Room', style: tt.displayMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Chat with people near you using Bluetooth. No internet or account needed. Up to 5 people per room.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _RoleCard.host(onTap: onHost),
                      const SizedBox(height: 14),
                      _RoleCard.join(onTap: onJoin),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.palette.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bluetooth on',
                      style: monoStyle(size: 12, color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Text(
                      'up to 5 people',
                      style: monoStyle(size: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard._({
    required this.filled,
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  const _RoleCard.host({VoidCallback? onTap})
    : this._(
        filled: true,
        icon: Icons.podcasts,
        badge: 'CREATE',
        title: 'Host a Chat',
        subtitle: 'Start a room. People nearby can find it and join.',
        onTap: onTap,
      );

  const _RoleCard.join({VoidCallback? onTap})
    : this._(
        filled: false,
        icon: Icons.search,
        badge: 'FIND',
        title: 'Join a Chat',
        subtitle: 'Look for a room nearby and join it.',
        onTap: onTap,
      );

  final bool filled;
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.lg);

    const onFilled = AppColors.onPrimary;
    final fg = filled ? onFilled : cs.onSurface;
    final subFg = filled
        ? onFilled.withValues(alpha: 0.95)
        : cs.onSurfaceVariant;
    final tint = palette.primarySoft;
    final accent = palette.primaryFg;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: filled ? AppColors.primaryGrad : null,
        color: filled ? null : cs.surface,
        border: filled ? null : Border.all(color: cs.outline, width: 1.5),
        boxShadow: [filled ? AppColors.shadowPrimary : palette.shadowCard],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: filled ? onFilled.withValues(alpha: 0.18) : tint,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: filled ? onFilled : accent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: filled
                              ? onFilled.withValues(alpha: 0.5)
                              : cs.outline,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: monoStyle(
                          size: 10,
                          weight: FontWeight.w600,
                          color: filled ? onFilled : cs.onSurfaceVariant,
                        ).copyWith(letterSpacing: 10 * 0.08),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 26,
                    height: 1.1,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: subFg,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
