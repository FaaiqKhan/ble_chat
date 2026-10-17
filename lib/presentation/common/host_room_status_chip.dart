import 'package:ble_chat/business_logic/host_session/host_session_state.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HostRoomStatusChip extends StatefulWidget {
  const HostRoomStatusChip({
    super.key,
    required this.full,
    required this.stopped,
    required this.status,
  });

  final bool full;
  final bool stopped;
  final HostSessionStatus status;

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
    final (label, bg, fg, dot, opacity) = switch (widget.status) {
      HostSessionStatus.idle => (
        "IDLE",
        palette.fullBg,
        Colors.white,
        Colors.white,
        const AlwaysStoppedAnimation(1.0),
      ),
      HostSessionStatus.starting || HostSessionStatus.closing => (
        widget.status == HostSessionStatus.starting ? "STARTING" : "CLOSING",
        palette.warningSoft,
        palette.warning,
        palette.warning,
        const AlwaysStoppedAnimation(1.0),
      ),
      HostSessionStatus.hosting when widget.full => (
        "FULL",
        palette.fullBg,
        Colors.white,
        Colors.white,
        const AlwaysStoppedAnimation(1.0),
      ),
      HostSessionStatus.hosting => (
        "OPEN TO JOIN",
        palette.successSoft,
        palette.success,
        palette.success,
        Tween(begin: 1.0, end: 0.15).animate(_blink),
      ),
      HostSessionStatus.closed || HostSessionStatus.failed => (
        widget.status == HostSessionStatus.closed ? "CLOSED" : "FAILED",
        palette.errorSoft,
        palette.error,
        palette.error,
        const AlwaysStoppedAnimation(1.0),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.status == HostSessionStatus.starting ||
                  widget.status == HostSessionStatus.closing
              ? CircularProgressIndicator(
                  color: dot,
                  strokeWidth: 2,
                  constraints: BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                    maxWidth: 14,
                    maxHeight: 14,
                  ),
                )
              : FadeTransition(
                  opacity: opacity,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
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
