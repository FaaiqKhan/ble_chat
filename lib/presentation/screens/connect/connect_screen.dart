import 'package:ble_chat/business_logic/connect_session/connect_session_bloc.dart';
import 'package:ble_chat/business_logic/connect_session/connect_session_event.dart';
import 'package:ble_chat/business_logic/connect_session/connect_session_state.dart';
import 'package:ble_chat/domain/entities/connect_session_progress.dart';
import 'package:ble_chat/presentation/common/ble_chat_outlined_button.dart';
import 'package:ble_chat/presentation/common/room_name_card.dart';
import 'package:ble_chat/presentation/common/screen_header.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/common/step_row.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final radius = BorderRadius.circular(AppRadius.lg);

    final connectSessionBloc = context.read<ConnectSessionBloc>();
    final room = connectSessionBloc.state.room;

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
                      SignalBars(rssi: room.rssi),
                    ],
                  ),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.medium,
                  ),
                  RoomNameCard(name: room.name, code: room.code),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.small,
                  ),
                  Text(
                    "Hosted by ${room.hostName}",
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
                        "${room.people} / ${room.maxPeople}",
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
                    child:
                        BlocSelector<
                          ConnectSessionBloc,
                          ConnectSessionState,
                          List<ConnectSessionProgress>
                        >(
                          selector: (state) => state.progress,
                          builder: (context, progress) => Column(
                            children: [
                              for (final step in progress)
                                StepRow(
                                  label: step.label,
                                  state: step.state,
                                  palette: palette,
                                ),
                            ],
                          ),
                        ),
                  ),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.medium,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: BleChatOutlinedButton(
                      onPressed: () =>
                          connectSessionBloc.state.status ==
                              ConnectSessionStatus.failed
                          ? Navigator.of(context).pop()
                          : connectSessionBloc.add(
                              DisconnectChatSessionEvent(),
                            ),
                      child:
                          connectSessionBloc.state.status ==
                              ConnectSessionStatus.failed
                          ? Text("Back")
                          : Text("Cancel"),
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
