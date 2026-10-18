import 'package:ble_chat/business_logic/join_room/join_room_bloc.dart';
import 'package:ble_chat/business_logic/join_room/join_room_event.dart';
import 'package:ble_chat/business_logic/join_room/join_room_state.dart';
import 'package:ble_chat/common/constants.dart';
import 'package:ble_chat/presentation/common/app_padding.dart';
import 'package:ble_chat/presentation/common/chat_icon_button.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  Widget _inputRoomNameWidget(TextTheme tt, ColorScheme cs) {
    final sectionLabel = tt.labelSmall?.copyWith(letterSpacing: 0.88);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ROOM NAME", style: sectionLabel),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.small,
        ),
        TextField(
          controller: controller,
          maxLength: maxNameLength,
          style: tt.titleMedium,
          decoration: InputDecoration(
            hintText: "e.g. GameNight",
            counterText: "",
            fillColor: cs.surface,
            enabledBorder: _border(cs.outline),
            focusedBorder: _border(cs.outline, width: 1.5),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final joinRoomBloc = context.read<JoinRoomBloc>();

    return Scaffold(
      appBar: AppBar(
        leading: ChatIconButton(
          iconData: Icons.arrow_back_ios_new_rounded,
          onPressed: Navigator.of(context).pop,
        ),
        title: Text("Join a Room", style: tt.headlineSmall),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppPadding.portraitScreen,
          child: Column(
            children: [
              _inputRoomNameWidget(tt, cs),
              ElevatedButton(
                onPressed: () =>
                    joinRoomBloc.add(ScanRoomEvent(controller.text)),
                child: Text("Search"),
              ),
              BlocSelector<JoinRoomBloc, JoinRoomState, JoinRoomStatus>(
                selector: (select) => select.status,
                builder: (_, status) {
                  return switch (status) {
                    JoinRoomStatus.idle => Text("In idle state"),
                    JoinRoomStatus.scanning => CircularProgressIndicator(),
                    JoinRoomStatus.scanned => Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            Text("Looking for a room..."),
                            Text("up to 10 seconds"),
                          ],
                        ),
                      ),
                    ),
                    JoinRoomStatus.joining => throw UnimplementedError(),
                    JoinRoomStatus.joined => const SizedBox.shrink(),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
