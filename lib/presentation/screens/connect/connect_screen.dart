import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/domain/entities/host_session_progress.dart';
import 'package:ble_chat/presentation/common/ble_chat_outlined_button.dart';
import 'package:ble_chat/presentation/common/room_name_card.dart';
import 'package:ble_chat/presentation/common/screen_header.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/common/step_row.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({
    super.key,
    required this._room,
    required this._authCode,
  });

  final FoundRoom _room;
  final String _authCode;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final radius = BorderRadius.circular(AppRadius.lg);

    return Scaffold(
      appBar: ScreenHeader(name: "Joining..."),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(width: 1.5, color: cs.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.warningSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          "CONNECTING",
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: palette.warning,
                          ),
                        ),
                      ),
                      SignalBars(rssi: _room.rssi),
                    ],
                  ),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.medium,
                  ),
                  RoomNameCard(name: _room.name, code: _room.code),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.small,
                  ),
                  Text(
                    "Hosted by ${_room.hostName}",
                    style: tt.bodyMedium?.copyWith(
                      fontFamily: AppFonts.mono,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.medium,
                  ),
                  Row(
                    children: [
                      Text(
                        "${_room.people} / ${_room.maxPeople}",
                        style: tt.bodyLarge,
                      ),
                      const SpacerBox(
                        type: SpacerBoxType.horizontal,
                        size: SpacerBoxSize.large,
                      ),
                      Text("people in the rom"),
                    ],
                  ),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.medium,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: BoxBorder.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        StepRow(
                          label: "Connecting to host",
                          state: StepStatus.done,
                          palette: palette,
                        ),
                        StepRow(
                          label: "Authenticating",
                          state: StepStatus.current,
                          palette: palette,
                        ),
                        StepRow(
                          label: "Discovering room service",
                          state: StepStatus.pending,
                          palette: palette,
                        ),
                      ],
                    ),
                  ),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.medium,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: BleChatOutlinedButton(
                      onPressed: () {
                        // Calls the bloc event to cancel the connection request
                      },
                      child: Text("Cancel"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
