import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/presentation/common/room_name_card.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/scan/widgets/room_code_entry.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A room found by the scan. Tapping it opens the 6-digit code entry
/// ([RoomCodeEntry]); the typed code is handed to [onVerify].
class FoundRoomCard extends StatefulWidget {
  const FoundRoomCard({
    super.key,
    required this.room,
    required this.onVerify,
    this.isVerifying = false,
    this.hasCodeError = false,
    this.onCodeChanged,
  });

  final FoundRoom room;

  /// Called with the 6 digits when Verify & Join is pressed.
  final ValueChanged<String> onVerify;

  /// The code is being checked with the host.
  final bool isVerifying;

  /// The last code entered was wrong.
  final bool hasCodeError;

  /// Called as the user types, so a shown error can be cleared.
  final ValueChanged<String>? onCodeChanged;

  @override
  State<FoundRoomCard> createState() => _FoundRoomCardState();
}

class _FoundRoomCardState extends State<FoundRoomCard> {
  late final FocusNode _codeFocus;
  late final ExpansibleController _expansibleController;

  @override
  void initState() {
    super.initState();
    _expansibleController = ExpansibleController();
    _codeFocus = FocusNode();
  }

  @override
  void didUpdateWidget(FoundRoomCard old) {
    super.didUpdateWidget(old);
    // The room became full or too weak while its code entry was open.
    if (!widget.room.isJoinable && _expansibleController.isExpanded) {
      _expansibleController.collapse();
    }
  }

  @override
  void dispose() {
    _expansibleController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_expansibleController.isExpanded) {
      _codeFocus.unfocus();
      _expansibleController.collapse();
    } else {
      _expansibleController.expand();
      // The code field exists once the body is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final radius = BorderRadius.circular(AppRadius.lg);

    // Gone, full or too weak to connect: dimmed, and taps do nothing.
    return Opacity(
      opacity: widget.room.isJoinable ? 1 : 0.5,
      // Rebuilds the card's colours and border whenever it expands or collapses.
      // (The controller notifies; nothing else would re-run this build.)
      child: ListenableBuilder(
        listenable: _expansibleController,
        builder: (context, child) {
          final expanded = _expansibleController.isExpanded;
          return Material(
            color: expanded ? palette.ctaSoft : cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                width: expanded ? 2 : 1.5,
                color: expanded ? cs.primary : cs.outline,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: child,
          );
        },
        // Built once; it handles its own expand / collapse.
        child: Expansible(
          controller: _expansibleController,
          // A closed card forgets what was typed.
          maintainState: false,
          // Only the header toggles; taps inside the code entry must not.
          headerBuilder: (context, _) => _cardBody(context),
          bodyBuilder: (context, _) => _roomCodeEntry(context, cs),
        ),
      ),
    );
  }

  Widget _cardBody(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return InkWell(
      onTap: widget.room.isJoinable ? _toggle : _toggle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoomNameCard(name: widget.room.name, code: widget.room.code),
                const SpacerBox(
                  type: SpacerBoxType.horizontal,
                  size: SpacerBoxSize.medium,
                ),
                SignalBars(rssi: widget.room.rssi, barWidth: 5),
              ],
            ),
            const SpacerBox(
              type: SpacerBoxType.vertical,
              size: SpacerBoxSize.medium,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${widget.room.people} / ${widget.room.maxPeople} people",
                    style: tt.bodyMedium?.copyWith(
                      fontFamily: AppFonts.mono,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),

                if (widget.room.isFull)
                  Text(
                    "FULL",
                    style: tt.titleSmall?.copyWith(color: palette.badFg),
                  )
                else if (!widget.room.isAvailable)
                  Text(
                    "NOT AVAILABLE",
                    style: tt.titleSmall?.copyWith(color: palette.badFg),
                  )
                else
                  Text(
                    _expansibleController.isExpanded
                        ? "ENTER CODE"
                        : "TAP TO JOIN",
                    style: tt.titleSmall?.copyWith(color: palette.primaryFg),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomCodeEntry(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: RoomCodeEntry(
        focusNode: _codeFocus,
        onVerify: widget.onVerify,
        hasError: widget.hasCodeError,
        onChanged: widget.onCodeChanged,
      ),
    );
  }
}
