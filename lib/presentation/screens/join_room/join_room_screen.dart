import 'package:ble_chat/business_logic/bluetooth_manager/bluetooth_manager_cubit.dart';
import 'package:ble_chat/business_logic/join_room/join_room_bloc.dart';
import 'package:ble_chat/business_logic/join_room/join_room_event.dart';
import 'package:ble_chat/business_logic/join_room/join_room_state.dart';
import 'package:ble_chat/presentation/common/app_padding.dart';
import 'package:ble_chat/presentation/common/chat_icon_button.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/join_room/widgets/scan_radar.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  static const _maxQueryLength = 20;

  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get _query => controller.text.trim();

  OutlineInputBorder _border(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    final joinRoomBloc = context.read<JoinRoomBloc>();
    final isBluetoothReady =
        context.select((BluetoothPermissionCubit c) => c.state.isBluetoothOn) ??
        false;

    return Scaffold(
      appBar: AppBar(
        leading: ChatIconButton(
          iconData: Icons.arrow_back_ios_new_rounded,
          onPressed: Navigator.of(context).pop,
        ),
        title: Text("Join a Chat", style: tt.headlineSmall),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppPadding.portraitScreen,
          child: BlocBuilder<JoinRoomBloc, JoinRoomState>(
            buildWhen: (a, b) => a.status != b.status,
            builder: (context, state) {
              final scanning = state.status == JoinRoomStatus.scanning;
              final canSearch = isBluetoothReady && _query.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ROOM NAME OR CODE",
                    style: tt.labelSmall?.copyWith(letterSpacing: 0.88),
                  ),
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.small,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: !scanning,
                          maxLength: _maxQueryLength,
                          style: tt.titleMedium,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            if (canSearch) {
                              joinRoomBloc.add(ScanRoomEvent(_query));
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Room name or code",
                            counterText: "",
                            fillColor: cs.surface,
                            enabledBorder: _border(cs.outline),
                            focusedBorder: _border(cs.outline, width: 1.5),
                            disabledBorder: _border(cs.outline),
                          ),
                        ),
                      ),
                      const SpacerBox(
                        type: SpacerBoxType.horizontal,
                        size: SpacerBoxSize.large,
                      ),
                      SizedBox(
                        height: 56,
                        child: scanning
                            ? OutlinedButton(
                                onPressed: () =>
                                    joinRoomBloc.add(StopScanRoomEvent()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.ctaFg,
                                ),
                                child: const Text("Cancel"),
                              )
                            : ElevatedButton(
                                onPressed: canSearch
                                    ? () => joinRoomBloc.add(
                                        ScanRoomEvent(_query),
                                      )
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  disabledBackgroundColor: cs.outline,
                                  disabledForegroundColor: cs.onSurfaceVariant,
                                ),
                                child: const Text("Search"),
                              ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: switch (state.status) {
                        JoinRoomStatus.idle => ScanRadar(
                          query: state.roomName,
                          isScanning: false,
                        ),
                        JoinRoomStatus.scanning => ScanRadar(
                          query: state.roomName,
                          isScanning: true,
                        ),
                        // Results and joining aren't designed here yet.
                        JoinRoomStatus.scanned ||
                        JoinRoomStatus.joining ||
                        JoinRoomStatus.joined => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
