import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Which colour an outlined button uses.
enum BleChatButtonTone {
  /// The blue used for ordinary actions (Cancel, Back, Keep Hosting).
  primary,

  /// Red, for actions that end or destroy something (Close Room).
  danger,
}

/// The app's outlined button. Shape, padding and text style come from the
/// theme's `outlinedButtonTheme`; this adds the colour [tone], so the text
/// and the border always match, in light and dark.
///
/// It wraps [OutlinedButton] instead of extending it: that keeps the few
/// options the app uses in one place, and the many it doesn't use out of sight.
class BleChatOutlinedButton extends StatelessWidget {
  const BleChatOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tone = BleChatButtonTone.primary,
  });

  /// Null disables the button.
  final VoidCallback? onPressed;
  final Widget child;
  final BleChatButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final color = switch (tone) {
      BleChatButtonTone.primary => palette.ctaFg,
      BleChatButtonTone.danger => palette.error,
    };

    return OutlinedButton(
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
          ).copyWith(
            // styleFrom can't colour the border per state; a disabled button
            // gets the neutral outline instead of the tone colour.
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? cs.outline
                    : color,
                width: 1.5,
              ),
            ),
          ),
      child: child,
    );
  }
}
