import 'package:ble_chat/presentation/screens/host_screen/host_screen.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

Future<void> confirmClose(
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
  if (close == true && context.mounted) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
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
            Text("Close this room?", style: tt.headlineSmall),
            const SizedBox(height: 8),
            Text(
              "This disconnects $others and stops advertising. The room can't "
              "be reopened with the same code.",
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: palette.error),
                child: const Text("Close Room"),
              ),
            ),
            const SizedBox(height: 10),
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
