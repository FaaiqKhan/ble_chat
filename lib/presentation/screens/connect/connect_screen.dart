import 'package:ble_chat/business_logic/connect_session/connect_session_bloc.dart';
import 'package:ble_chat/business_logic/connect_session/connect_session_event.dart';
import 'package:ble_chat/business_logic/connect_session/connect_session_state.dart';
import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/presentation/common/app_padding.dart';
import 'package:ble_chat/presentation/common/ble_chat_outlined_button.dart';
import 'package:ble_chat/presentation/common/failed_banner.dart';
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

    final connectSessionBloc = context.read<ConnectSessionBloc>();
    final room = connectSessionBloc.state.room;

    return Scaffold(
      appBar: const ScreenHeader(name: "Join a Chat"),
      body: SafeArea(
        child: BlocConsumer<ConnectSessionBloc, ConnectSessionState>(
          // Cancel was pressed and the disconnect finished: leave the screen.
          listenWhen: (before, after) =>
              before.status != after.status &&
              after.status == ConnectSessionStatus.disconnected,
          listener: (context, _) => Navigator.of(context).pop(),
          builder: (context, state) {
            final failed = state.status == ConnectSessionStatus.failed;
            // The attempt is over, one way or another: nothing left to cancel.
            final ended = failed || state.status == ConnectSessionStatus.lost;

            // The tag on the card, and the colour of its border.
            final (
              tag,
              tagBackground,
              tagColor,
              borderColor,
            ) = switch (state.status) {
              ConnectSessionStatus.connecting => (
                "CONNECTING",
                palette.warningSoft,
                palette.warnFg,
                cs.outline,
              ),
              ConnectSessionStatus.disconnecting => (
                "LEAVING",
                palette.warningSoft,
                palette.warnFg,
                cs.outline,
              ),
              ConnectSessionStatus.connected => (
                "JOINED",
                palette.successSoft,
                palette.okFg,
                palette.success,
              ),
              ConnectSessionStatus.failed => (
                "FAILED",
                palette.errorSoft,
                palette.badFg,
                palette.error,
              ),
              ConnectSessionStatus.lost => (
                "CONNECTION LOST",
                palette.errorSoft,
                palette.badFg,
                palette.error,
              ),
              ConnectSessionStatus.disconnected => (
                "DISCONNECTED",
                cs.surfaceContainerHigh,
                cs.onSurfaceVariant,
                cs.outline,
              ),
            };

            final (signalLabel, signalColor) = switch (bluetoothSignalOf(
              state.signal,
            )) {
              BluetoothSignal.good => ("Strong signal", palette.okFg),
              BluetoothSignal.weak => ("Weak signal", palette.warnFg),
              BluetoothSignal.poor => ("Very weak signal", palette.badFg),
            };

            return SingleChildScrollView(
              padding: AppPadding.portraitScreen,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [palette.shadowCard],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagBackground,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontFamily: AppFonts.mono,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: tagColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            SignalBars(rssi: state.signal, barWidth: 5),
                            const SpacerBox(
                              type: SpacerBoxType.horizontal,
                              size: SpacerBoxSize.medium,
                            ),
                            Text(
                              signalLabel,
                              style: tt.bodySmall?.copyWith(
                                fontFamily: AppFonts.mono,
                                color: signalColor,
                              ),
                            ),
                          ],
                        ),
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
                        color: cs.onSurfaceVariant,
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
                          style: tt.titleLarge?.copyWith(
                            fontFamily: AppFonts.mono,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SpacerBox(
                          type: SpacerBoxType.horizontal,
                          size: SpacerBoxSize.medium,
                        ),
                        Text(
                          "people in the room",
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SpacerBox(
                      type: SpacerBoxType.vertical,
                      size: SpacerBoxSize.medium,
                    ),
                    // What went wrong, above the steps so it is the first thing seen.
                    if (ended) ...[
                      _banner(state),
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.medium,
                      ),
                    ],
                    // The steps: connect, discover, authenticate, join.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.outlineVariant),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            for (final step in state.progress)
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
                    if (failed) ...[
                      // The same wrong code would fail again, so retrying is only
                      // offered when something else went wrong.
                      if (!state.isWrongCode) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => connectSessionBloc.add(
                              ConnectChatSessionEvent(),
                            ),
                            style: ElevatedButton.styleFrom(
                              shadowColor: palette.ctaFg.withValues(
                                alpha: 0.24,
                              ),
                              elevation: 8,
                            ),
                            child: const Text("Try Again"),
                          ),
                        ),
                        const SpacerBox(
                          type: SpacerBoxType.vertical,
                          size: SpacerBoxSize.medium,
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: BleChatOutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Back"),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: BleChatOutlinedButton(
                          // Lost: just go back. Still joining: disconnect, and the
                          // listener above leaves once that is done.
                          onPressed:
                              state.status == ConnectSessionStatus.disconnecting
                              ? null
                              : () => ended
                                    ? Navigator.of(context).pop()
                                    : connectSessionBloc.add(
                                        DisconnectChatSessionEvent(),
                                      ),
                          child: Text(ended ? "Back" : "Cancel"),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The red banner shown when joining failed or the link was lost.
  Widget _banner(ConnectSessionState state) {
    if (state.status == ConnectSessionStatus.lost) {
      return const FailedBanner(
        title: "Connection lost",
        message: "The connection to the host was lost.",
      );
    }
    if (state.isWrongCode) {
      return const FailedBanner(
        title: "That code didn’t match",
        message: "Go back and check it with the host.",
      );
    }
    return FailedBanner(
      title: "Couldn’t join the room",
      message: state.errorMessage ?? "The host didn’t respond. Try again.",
    );
  }
}
