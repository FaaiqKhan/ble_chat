import 'package:ble_chat/domain/entities/host_session_progress.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StepRow extends StatelessWidget {
  const StepRow({
    super.key,
    required this.label,
    required this.state,
    required this.palette,
  });

  final String label;
  final StepStatus state;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final (ring, fill, fg, tag, tagFg, bg) = switch (state) {
      StepStatus.done => (
        palette.okFg,
        palette.successSoft,
        cs.onSurface,
        "DONE",
        palette.okFg,
        Colors.transparent,
      ),
      StepStatus.current => (
        palette.primaryBorder,
        palette.primarySoft,
        cs.onSurface,
        "NOW",
        palette.primaryFg,
        palette.primarySoft,
      ),
      StepStatus.pending => (
        cs.outline,
        Colors.transparent,
        cs.onSurfaceVariant,
        "",
        cs.onSurfaceVariant,
        Colors.transparent,
      ),
      StepStatus.failed => (
        palette.badFg,
        palette.errorSoft,
        palette.badFg,
        "FAILED",
        palette.badFg,
        palette.errorSoft,
      ),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: ring, width: 2),
            ),
            child: switch (state) {
              StepStatus.done => Icon(
                Icons.check,
                size: 14,
                color: palette.okFg,
              ),
              StepStatus.failed => Icon(
                Icons.close,
                size: 12,
                color: palette.badFg,
              ),
              StepStatus.current => SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: palette.primaryFg,
                  backgroundColor: palette.primaryBorder,
                ),
              ),
              StepStatus.pending => null,
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: tt.titleSmall?.copyWith(color: fg)),
          ),
          Text(
            tag,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: tagFg,
            ),
          ),
        ],
      ),
    );
  }
}
