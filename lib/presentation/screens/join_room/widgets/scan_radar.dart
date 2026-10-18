import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The "Looking for a room…" view: three purple rings ripple out from a
/// Bluetooth badge while the scan runs.
class ScanRadar extends StatefulWidget {
  const ScanRadar({super.key, required this.query});

  final String query;

  @override
  State<ScanRadar> createState() => _ScanRadarState();
}

class _ScanRadarState extends State<ScanRadar>
    with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 2400);

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: _cycle,
  )..repeat();

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ripple,
                  builder: (_, _) => CustomPaint(
                    painter: _RingsPainter(
                      progress: reduceMotion ? 0.6 : _ripple.value,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          "Looking for a room…",
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "“${widget.query}” · up to 10 seconds",
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(
            fontFamily: AppFonts.mono,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  // Each ring starts 1/3 of a cycle after the previous one (0.8s of 2.4s).
  static const _ringCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    for (var i = 0; i < _ringCount; i++) {
      final phase = (progress - i / _ringCount) % 1.0;
      canvas.drawCircle(
        center,
        maxRadius * (0.25 + 0.75 * phase),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.8 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.progress != progress || old.color != color;
}
