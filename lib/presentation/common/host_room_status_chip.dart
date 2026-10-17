import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HostRoomStatusChip extends StatefulWidget {
  const HostRoomStatusChip({
    super.key,
    required this.full,
    required this.stopped,
  });

  final bool full;
  final bool stopped;

  @override
  State<HostRoomStatusChip> createState() => _HostRoomStatusChipState();
}

class _HostRoomStatusChipState extends State<HostRoomStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (label, bg, fg, dot) = widget.full
        ? ("FULL", palette.fullBg, Colors.white, Colors.white)
        : widget.stopped
        ? ("STOPPED", palette.errorSoft, palette.error, palette.error)
        : ("OPEN TO JOIN", palette.successSoft, palette.okFg, palette.success);
    final animate = !widget.full && !widget.stopped;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: animate
                ? Tween(begin: 1.0, end: 0.15).animate(_blink)
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
