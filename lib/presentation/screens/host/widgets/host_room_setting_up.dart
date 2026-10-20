import 'package:ble_chat/business_logic/host_session/host_session_bloc.dart';
import 'package:ble_chat/business_logic/host_session/host_session_state.dart';
import 'package:ble_chat/domain/entities/host_session_progress.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/common/step_row.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HostRoomSettingUp extends StatelessWidget {
  const HostRoomSettingUp({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STARTING YOUR ROOM",
          style: tt.labelSmall?.copyWith(letterSpacing: 0.88),
        ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.small,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child:
                BlocSelector<
                  HostSessionBloc,
                  HostSessionState,
                  List<HostSessionProgress>
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
        ),
        const SpacerBox(
          type: SpacerBoxType.vertical,
          size: SpacerBoxSize.small,
        ),
        Text(
          "Keep this screen open. This usually takes a few seconds.",
          style: tt.bodySmall,
        ),
      ],
    );
  }
}
