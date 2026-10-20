import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/host/host_room_screen.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

Future<bool> confirmClose(
  BuildContext context,
  List<HostParticipant> participants,
) async {
  final close = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => CloseRoomSheet(
      others: participants.isEmpty
          ? 'anyone who joins'
          : participants.length == 1
          ? '1 person'
          : '${participants.length} people',
    ),
  );
  return close == true && context.mounted;
}

class CloseRoomSheet extends StatelessWidget {
  const CloseRoomSheet({super.key, required this.others});

  final String others;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: palette.errorSoft,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(Icons.warning_amber, color: palette.error),
            ),
            const SpacerBox(
              type: SpacerBoxType.vertical,
              size: SpacerBoxSize.large,
            ),
            Text("End this room for everyone?", style: tt.headlineMedium),
            const SpacerBox(
              type: SpacerBoxType.vertical,
              size: SpacerBoxSize.medium,
            ),
            Text(
              "Closing the room removes $others straight away.\nThey will see \"The host ended this chat\". This can't be undone.",
              style: tt.bodyMedium,
            ),
            const SpacerBox(
              type: SpacerBoxType.vertical,
              size: SpacerBoxSize.large,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: palette.error),
                child: const Text("Close Room"),
              ),
            ),
            const SpacerBox(
              type: SpacerBoxType.vertical,
              size: SpacerBoxSize.medium,
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Keep Hosting"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
