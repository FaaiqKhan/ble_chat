import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The "Looking for a room…" view: three purple rings ripple out from a
/// Bluetooth badge while the scan runs.
class ScanRadar extends StatefulWidget {
  const ScanRadar({super.key, required this.query, required this.isScanning});

  final String query;
  final bool isScanning;

  @override
  State<ScanRadar> createState() => _ScanRadarState();
}

class _ScanRadarState extends State<ScanRadar>
    with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 2400);

  // Not started here: the ticker would fire every frame even while idle.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(ScanRadar old) {
    super.didUpdateWidget(old);
    _syncAnimation();
  }

  /// Rings only animate while scanning, and not with reduced motion.
  void _syncAnimation() {
    final animate =
        widget.isScanning && !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      if (!_ripple.isAnimating) _ripple.repeat();
    } else {
      _ripple.stop();
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isScanning)
          // Own layer, so the ripple repaints without touching the screen.
          RepaintBoundary(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      // `repaint` redraws on every tick without rebuilding
                      // any widgets.
                      painter: _RingsPainter(
                        animation: _ripple,
                        color: AppColors.primary,
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
          )
        else
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.radar, size: 28, color: cs.onSurfaceVariant),
          ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.large,
        ),
        Text(
          widget.isScanning ? "Looking for a room…" : "Not searching",
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.medium,
        ),
        Text(
          widget.isScanning
              ? "“${widget.query}” · up to 10 seconds"
              : "Type the room name with code from your host, then tap search.",
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(
            // Mono for the query only; the idle hint is plain copy.
            fontFamily: widget.isScanning ? AppFonts.mono : null,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.animation, required this.color})
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  // Each ring starts 1/3 of a cycle after the previous one (0.8s of 2.4s).
  static const _ringCount = 3;

  // One Paint reused for every ring and frame.
  final _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;
    // A stopped controller (idle or reduced motion) shows a static frame.
    final progress = animation.isAnimating ? animation.value : 0.6;

    for (var i = 0; i < _ringCount; i++) {
      final phase = (progress - i / _ringCount) % 1.0;
      canvas.drawCircle(
        center,
        maxRadius * (0.25 + 0.75 * phase),
        _paint..color = color.withValues(alpha: 0.8 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.animation != animation || old.color != color;
}
