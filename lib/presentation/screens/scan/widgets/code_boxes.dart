import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A row of boxes showing a numeric code as it is typed.
///
/// The boxes only display. A real, invisible text field lies over them, so
/// tapping a box opens the number keyboard and autofill / paste still work.
/// The text lives in [controller], which the owner reads.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    required this.focusNode,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;

  /// False locks the field, e.g. while the code is being checked.
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Redraws the boxes whenever the typed text changes.
        ListenableBuilder(
          listenable: controller,
          builder: (_, _) {
            final text = controller.text;
            return Row(
              children: [
                for (var i = 0; i < length; i++) ...[
                  if (i > 0)
                    const SpacerBox(
                      type: SpacerBoxType.horizontal,
                      size: SpacerBoxSize.medium,
                    ),
                  Expanded(
                    child: _CodeBox(
                      digit: i < text.length ? text[i] : "",
                      isNext: i == text.length && enabled,
                      hasError: hasError,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              maxLength: length,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enableInteractiveSelection: false,
              showCursor: false,
              decoration: const InputDecoration.collapsed(hintText: ""),
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.digit,
    required this.isNext,
    required this.hasError,
  });

  final String digit;

  /// The box the next digit will go in.
  final bool isNext;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final borderColor = hasError
        ? palette.error
        : isNext
        ? AppColors.cta
        : digit.isNotEmpty
        ? cs.outline
        : cs.outlineVariant;
    final background = hasError
        ? palette.errorSoft
        : isNext
        ? palette.ctaSoft
        : cs.surface;

    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
