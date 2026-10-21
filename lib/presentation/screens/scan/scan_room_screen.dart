import 'package:ble_chat/business_logic/bluetooth_manager/bluetooth_manager_cubit.dart';
import 'package:ble_chat/business_logic/scan_session/scan_session_bloc.dart';
import 'package:ble_chat/business_logic/scan_session/scan_session_event.dart';
import 'package:ble_chat/business_logic/scan_session/scan_session_state.dart';
import 'package:ble_chat/presentation/common/app_padding.dart';
import 'package:ble_chat/presentation/common/chat_icon_button.dart';
import 'package:ble_chat/presentation/screens/scan/widgets/room_not_found_card.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/scan/widgets/found_room_list.dart';
import 'package:ble_chat/presentation/screens/scan/widgets/scan_radar.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanRoomScreen extends StatefulWidget {
  const ScanRoomScreen({super.key});

  @override
  State<ScanRoomScreen> createState() => _ScanRoomScreenState();
}

class _ScanRoomScreenState extends State<ScanRoomScreen> {
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

    final scanSessionBloc = context.read<ScanSessionBloc>();
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
          child: BlocBuilder<ScanSessionBloc, ScanSessionState>(
            buildWhen: (a, b) =>
                a.status != b.status ||
                a.rooms != b.rooms ||
                a.query != b.query,
            builder: (context, state) {
              final scanning = state.status == ScanSessionStatus.scanning;
              final canSearch = isBluetoothReady && _query.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ROOM NAME",
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
                              scanSessionBloc.add(ScanRoomEvent(_query));
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Room name",
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
                                    scanSessionBloc.add(StopScanRoomEvent()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.ctaFg,
                                ),
                                child: const Text("Cancel"),
                              )
                            : ElevatedButton(
                                onPressed: canSearch
                                    ? () => scanSessionBloc.add(
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
                  const SpacerBox(
                    type: SpacerBoxType.vertical,
                    size: SpacerBoxSize.medium,
                  ),
                  Expanded(
                    child: Center(
                      child: switch (state.status) {
                        ScanSessionStatus.idle => ScanRadar(
                          query: state.query,
                          isScanning: false,
                        ),
                        // Nothing found yet: the radar. Once rooms appear they
                        // are listed while the search carries on.
                        ScanSessionStatus.scanning when state.rooms.isEmpty =>
                          ScanRadar(query: state.query, isScanning: true),
                        ScanSessionStatus.scanning => FoundRoomList(
                          rooms: state.rooms,
                          scanning: true,
                          query: _query,
                        ),
                        ScanSessionStatus.scanned => FoundRoomList(
                          rooms: state.rooms,
                          scanning: false,
                          query: _query,
                        ),
                        ScanSessionStatus.notFound => Align(
                          alignment: Alignment.topCenter,
                          child: NotFoundRoomCard(query: state.query),
                        ),
                        ScanSessionStatus.failed => _ScanMessage(
                          title: "Couldn't search",
                          message:
                              state.errorMessage ??
                              "Something went wrong. Try again.",
                        ),
                        // Joining isn't designed here yet.
                        ScanSessionStatus.joining ||
                        ScanSessionStatus.joined => const SizedBox.shrink(),
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

class _ScanMessage extends StatelessWidget {
  const _ScanMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
