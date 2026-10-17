import 'dart:math';

import 'package:ble_chat/business_logic/bluetooth_manager/bluetooth_manager_cubit.dart';
import 'package:ble_chat/business_logic/host_session/host_session_bloc.dart';
import 'package:ble_chat/business_logic/host_session/host_session_state.dart';
import 'package:ble_chat/common/constants.dart';
import 'package:ble_chat/presentation/common/app_padding.dart';
import 'package:ble_chat/presentation/common/chat_icon_button.dart';
import 'package:ble_chat/presentation/common/max_people_option.dart';
import 'package:ble_chat/presentation/common/room_label_card.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/host_screen/host_screen.dart';
import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateRoom extends StatefulWidget {
  const CreateRoom({super.key});

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {
  late final TextEditingController controller;
  late final String code;
  bool touched = false;
  int maxPeople = 2;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController()..addListener(() => setState(() {}));
    final rnd = Random.secure();
    code = List.generate(
      4,
      (_) => codeChars[rnd.nextInt(codeChars.length)],
    ).join();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get _name => controller.text.trim();

  String? get _error {
    final name = _name;
    if (name.isEmpty) return 'Enter a room name';
    if (name.length < 3) return 'Use at least 3 characters';
    if (!validChars.hasMatch(name)) {
      return 'Use letters, numbers, spaces, - _ or . only';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;
    final isBluetoothReady =
        context.select((BluetoothPermissionCubit c) => c.state.isBluetoothOn) ??
        false;

    final error = _error;
    final showError = error != null && (touched || controller.text.isNotEmpty);
    final canStart = error == null && isBluetoothReady;

    final borderColor = showError
        ? palette.error
        : error != null
        ? cs.outline
        : palette.success;
    final messageColor = showError
        ? palette.error
        : error != null
        ? cs.onSurfaceVariant
        : palette.okFg;
    final message = showError
        ? error
        : error != null
        ? '3–16 characters. Anyone nearby can see it.'
        : 'Valid name';
    final messageIcon = showError
        ? Icons.error_outline
        : error != null
        ? Icons.info_outline
        : Icons.check;

    final sectionLabel = tt.labelSmall?.copyWith(letterSpacing: 0.88);

    return Scaffold(
      appBar: AppBar(
        leading: ChatIconButton(
          iconData: Icons.arrow_back_ios_new_rounded,
          onPressed: Navigator.of(context).pop,
        ),
        title: Text("Room Setup", style: tt.headlineSmall),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppPadding.portraitScreen,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ROOM NAME", style: sectionLabel),
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.small,
                      ),
                      Focus(
                        onFocusChange: (focused) {
                          if (!focused) setState(() => touched = true);
                        },
                        child: TextField(
                          controller: controller,
                          maxLength: maxNameLength,
                          style: tt.titleMedium,
                          decoration: InputDecoration(
                            hintText: "e.g. GameNight",
                            counterText: "",
                            fillColor: cs.surface,
                            suffixText:
                                "${controller.text.length}/$maxNameLength",
                            suffixStyle: tt.bodySmall?.copyWith(
                              fontFamily: AppFonts.mono,
                            ),
                            enabledBorder: _border(borderColor),
                            focusedBorder: _border(borderColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.small,
                      ),
                      Row(
                        children: [
                          Icon(messageIcon, size: 14, color: messageColor),
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
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.large,
                      ),
                      Text("ROOM LABEL · WHAT OTHERS SEE", style: sectionLabel),
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.small,
                      ),
                      RoomLabelCard(
                        name: _name.isEmpty ? 'RoomName' : _name,
                        code: code,
                        dimmed: error != null,
                      ),
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.large,
                      ),
                      Text("MAX PEOPLE", style: sectionLabel),
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.medium,
                      ),
                      Row(
                        children: [
                          for (final n in participantOptions) ...[
                            if (n != participantOptions.first)
                              const SpacerBox(
                                type: SpacerBoxType.horizontal,
                                size: SpacerBoxSize.medium,
                              ),
                            Expanded(
                              child: MaxPeopleOption(
                                value: n,
                                selected: n == maxPeople,
                                onTap: () => setState(() => maxPeople = n),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SpacerBox(
                        type: SpacerBoxType.vertical,
                        size: SpacerBoxSize.small,
                      ),
                      Text(
                        "Includes you. A room holds up to 5 people.",
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!canStart) {
                      setState(() => touched = true);
                      return;
                    }
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => HostSessionBloc(
                            HostSessionState(
                              code: code,
                              roomName: _name,
                              maxPeople: maxPeople,
                            ),
                          ),
                          child: HostScreen(),
                        ),
                      ),
                    );
                  },
                  style: canStart
                      ? ElevatedButton.styleFrom(
                          shadowColor: AppColors.cta.withValues(alpha: 0.24),
                          elevation: 8,
                        )
                      : ElevatedButton.styleFrom(
                          backgroundColor: cs.outline,
                          foregroundColor: cs.onSurfaceVariant,
                        ),
                  child: const Text("Start Hosting"),
                ),
              ),
              const SpacerBox(
                type: SpacerBoxType.vertical,
                size: SpacerBoxSize.small,
              ),
              Text(
                !isBluetoothReady
                    ? "Turn on Bluetooth to start your room"
                    : error != null
                    ? "Fix the room name to continue"
                    : "People nearby can find your room right away",
                style: tt.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
}
