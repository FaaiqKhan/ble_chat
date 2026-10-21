import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/scan/widgets/code_boxes.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The "enter the room's 6-digit code" panel: code boxes, a message, and a
/// Verify & Join button.
///
/// It knows nothing about joining. Pressing the button hands the typed code to
/// [onVerify]; whether it is being checked ([isVerifying]) or was wrong
/// ([hasError]) is decided by the parent and passed back in.
class RoomCodeEntry extends StatefulWidget {
  const RoomCodeEntry({
    super.key,
    required this.onVerify,
    this.focusNode,
    this.isVerifying = false,
    this.hasError = false,
    this.onChanged,
  });

  static const codeLength = 6;

  /// Called with the 6 digits when Verify & Join is pressed.
  final ValueChanged<String>? onVerify;

  /// Lets the parent focus the field, e.g. when the panel opens.
  final FocusNode? focusNode;

  /// The code is being checked: field locked, button shows "Checking…".
  final bool isVerifying;

  /// The last code was wrong: boxes turn red, and clear.
  final bool hasError;

  /// Called as the user types, so the parent can clear a shown error.
  final ValueChanged<String>? onChanged;

  @override
  State<RoomCodeEntry> createState() => _RoomCodeEntryState();
}

class _RoomCodeEntryState extends State<RoomCodeEntry> {
  late final TextEditingController _code;
  FocusNode? _ownFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _code = TextEditingController()..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(RoomCodeEntry old) {
    super.didUpdateWidget(old);
    // A wrong code: start over, ready to type again.
    if (!old.hasError && widget.hasError) {
      _code.clear();
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final ready =
        _code.text.length == RoomCodeEntry.codeLength && !widget.isVerifying;

    final message = widget.isVerifying
        ? "Checking code…"
        : widget.hasError
        ? "That code didn’t match. Check it with the host and try again."
        : "Ask the host for the 6-digit code.";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ROOM CODE · ${RoomCodeEntry.codeLength} DIGITS",
          style: tt.labelSmall?.copyWith(letterSpacing: 0.88),
        ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.medium,
        ),
        CodeBoxes(
          controller: _code,
          focusNode: _focus,
          length: RoomCodeEntry.codeLength,
          enabled: !widget.isVerifying,
          hasError: widget.hasError,
          onChanged: widget.onChanged,
        ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.medium,
        ),
        Text(
          message,
          style: tt.bodySmall?.copyWith(
            color: widget.hasError ? palette.badFg : cs.onSurfaceVariant,
            fontWeight: widget.hasError ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.medium,
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: ready && widget.onVerify != null
                ? () => widget.onVerify!(_code.text)
                : null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: widget.isVerifying
                  ? palette.ctaSoft
                  : cs.outline,
              disabledForegroundColor: widget.isVerifying
                  ? palette.ctaFg
                  : cs.onSurfaceVariant,
            ),
            child: widget.isVerifying
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: palette.ctaFg,
                          backgroundColor: palette.primaryBorder,
                        ),
                      ),
                      const SpacerBox(
                        type: SpacerBoxType.horizontal,
                        size: SpacerBoxSize.large,
                      ),
                      const Text("Checking…"),
                    ],
                  )
                : const Text("Verify & Join"),
          ),
        ),
      ],
    );
  }
}
