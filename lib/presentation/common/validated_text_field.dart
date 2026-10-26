import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A labelled text field that tells the user, below it, whether what they typed is
/// fine: a grey hint while it's still empty, a red message once it is wrong, and a
/// green tick when it is valid. The border follows the same three states.
///
/// It is a [TextFormField], so it works inside a [Form] (`validate()` runs its
/// [validator]). The message row is drawn here rather than as the field's own error
/// text, because the design shows an icon and three states.
class ValidatedTextField extends StatefulWidget {
  const ValidatedTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    required this.maxLength,
    required this.hintText,
    required this.neutralMessage,
    this.validMessage = 'Valid name',
    this.showErrors = false,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction,
  });

  /// Small caps label above the field, e.g. "ROOM NAME".
  final String label;
  final TextEditingController controller;

  /// Returns the error for the trimmed text, or null when it is valid.
  final String? Function(String value) validator;
  final int maxLength;
  final String hintText;

  /// Shown while the field is empty and untouched.
  final String neutralMessage;
  final String validMessage;

  /// Show an error even if the user never touched the field, e.g. after pressing a
  /// disabled submit button.
  final bool showErrors;

  /// False locks the field, e.g. while connecting; it keeps showing its value.
  final bool enabled;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    // Redraw the counter and the message as the user types.
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(ValidatedTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final text = widget.controller.text;
    final error = widget.validator(text.trim());
    final showError =
        error != null && (_touched || text.isNotEmpty || widget.showErrors);

    final (borderColor, messageColor, message, icon) = showError
        ? (palette.error, palette.error, error, Icons.error_outline)
        : error != null
        ? (
            cs.outline,
            cs.onSurfaceVariant,
            widget.neutralMessage,
            Icons.info_outline,
          )
        : (palette.success, palette.okFg, widget.validMessage, Icons.check);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: tt.labelSmall?.copyWith(letterSpacing: 0.88)),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.small,
        ),
        Focus(
          // Leaving the field counts as touching it, so an empty one then shows its error.
          onFocusChange: (focused) {
            if (!focused) setState(() => _touched = true);
          },
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            maxLength: widget.maxLength,
            style: tt.titleMedium,
            textCapitalization: widget.textCapitalization,
            textInputAction: widget.textInputAction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => widget.validator((value ?? '').trim()),
            decoration: InputDecoration(
              hintText: widget.hintText,
              counterText: "",
              fillColor: cs.surface,
              suffixText: "${text.length}/${widget.maxLength}",
              suffixStyle: tt.bodySmall?.copyWith(fontFamily: AppFonts.mono),
              enabledBorder: _border(borderColor),
              focusedBorder: _border(borderColor),
              disabledBorder: _border(borderColor),
              errorBorder: _border(palette.error),
              focusedErrorBorder: _border(palette.error),
              // The message row below shows the error, so the field's own is hidden.
              errorStyle: const TextStyle(fontSize: 0, height: 0),
            ),
          ),
        ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.small,
        ),
        Row(
          children: [
            Icon(icon, size: 14, color: messageColor),
            const SpacerBox(
              type: SpacerBoxType.horizontal,
              size: SpacerBoxSize.small,
            ),
            Expanded(
              child: Text(
                message,
                style: tt.labelMedium?.copyWith(
                  color: messageColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
