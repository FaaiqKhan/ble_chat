import 'package:ble_chat/business_logic/bluetooth_manager/bluetooth_manager_cubit.dart';
import 'package:ble_chat/business_logic/host_session/host_session_bloc.dart';
import 'package:ble_chat/business_logic/host_session/host_session_event.dart';
import 'package:ble_chat/business_logic/host_session/host_session_state.dart';
import 'package:ble_chat/common/constants.dart';
import 'package:ble_chat/common/validators.dart';
import 'package:ble_chat/data/repository_impl/host_session_repository_impl.dart';
import 'package:ble_chat/presentation/common/app_padding.dart';
import 'package:ble_chat/presentation/common/max_people_option.dart';
import 'package:ble_chat/presentation/common/room_label_card.dart';
import 'package:ble_chat/presentation/common/screen_header.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/common/validated_text_field.dart';
import 'package:ble_chat/presentation/screens/host/host_room_screen.dart';
import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateRoom extends StatefulWidget {
  const CreateRoom({super.key});

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNameController;
  late final TextEditingController _hostNameController;
  late final String code;
  int maxPeople = 2;

  // Start Hosting was pressed while something was wrong: show every error.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Redraws the label preview and the Start button as the user types.
    _roomNameController = TextEditingController()
      ..addListener(() => setState(() {}));
    _hostNameController = TextEditingController()
      ..addListener(() => setState(() {}));
    code = generateCode();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _hostNameController.dispose();
    super.dispose();
  }

  String get _name => _roomNameController.text.trim();

  String get _hostName => _hostNameController.text.trim();

  void _startHosting() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => HostSessionBloc(
            HostSessionState(
              code: code,
              roomName: _name,
              hostName: _hostName,
              maxPeople: maxPeople,
            ),
            hostSessionRepository: HostSessionRepositoryImpl(),
          )..add(StartHostingEvent()),
          child: HostRoomScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isBluetoothReady =
        context.select((BluetoothPermissionCubit c) => c.state.isBluetoothOn) ??
        false;

    final roomNameError = validateRoomName(_name);
    final canStart =
        roomNameError == null &&
        validateHostName(_hostName) == null &&
        isBluetoothReady;

    final sectionLabel = tt.labelSmall?.copyWith(letterSpacing: 0.88);

    return Scaffold(
      appBar: const ScreenHeader(name: "Room Setup"),
      body: SafeArea(
        child: Padding(
          padding: AppPadding.portraitScreen,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValidatedTextField(
                          label: "YOUR NAME",
                          controller: _hostNameController,
                          validator: validateHostName,
                          maxLength: maxPlayerNameLength,
                          hintText: "e.g. Faiq",
                          neutralMessage:
                              "2–$maxPlayerNameLength characters. Shown to people in the room.",
                          showErrors: _submitted,
                          textInputAction: TextInputAction.next,
                        ),
                        const SpacerBox(
                          type: SpacerBoxType.vertical,
                          size: SpacerBoxSize.large,
                        ),
                        ValidatedTextField(
                          label: "ROOM NAME",
                          controller: _roomNameController,
                          validator: validateRoomName,
                          maxLength: maxRoomNameLength,
                          hintText: "e.g. GameNight",
                          neutralMessage:
                              "3–$maxRoomNameLength characters. Anyone nearby can see it.",
                          showErrors: _submitted,
                          textInputAction: TextInputAction.done,
                        ),
                        const SpacerBox(
                          type: SpacerBoxType.vertical,
                          size: SpacerBoxSize.large,
                        ),
                        Text(
                          "ROOM LABEL · WHAT OTHERS SEE",
                          style: sectionLabel,
                        ),
                        const SpacerBox(
                          type: SpacerBoxType.vertical,
                          size: SpacerBoxSize.small,
                        ),
                        RoomLabelCard(
                          name: _name.isEmpty ? 'RoomName' : _name,
                          code: code,
                          dimmed: roomNameError != null,
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
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!canStart) {
                      // Runs every field's validator, and makes the fields show
                      // their errors even if they were never touched.
                      _formKey.currentState?.validate();
                      setState(() => _submitted = true);
                      return;
                    }
                    _startHosting();
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
              // Always takes its height, so the layout doesn't jump when it appears.
              SizedBox(
                height: 16,
                child: Text(
                  isBluetoothReady
                      ? ""
                      : "Turn on Bluetooth to start your room",
                  style: tt.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
