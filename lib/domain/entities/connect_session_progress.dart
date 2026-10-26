import 'package:ble_chat/common/step_status.dart';

/// In the order they happen: the room's code characteristic can only be found by
/// discovering services, so the code is sent after discovery, not before.
/// Native reports each of these names when the step is done.
enum ConnectSessionProgressStep { connect, discover, authenticate, join }

class ConnectSessionProgress {
  const ConnectSessionProgress({required this.step, required this.state});

  final ConnectSessionProgressStep step;
  final StepStatus state;

  String get label => switch (step) {
    ConnectSessionProgressStep.connect => "Connecting to host",
    ConnectSessionProgressStep.discover => "Discovering room service",
    ConnectSessionProgressStep.authenticate => "Authenticating",
    ConnectSessionProgressStep.join => "Joining room",
  };

  /// Nothing started yet: every step pending (shown before Connect is pressed).
  static List<ConnectSessionProgress> allPending() => [
    for (final step in ConnectSessionProgressStep.values)
      ConnectSessionProgress(step: step, state: StepStatus.pending),
  ];

  /// Every step pending except the first, which is in progress.
  static List<ConnectSessionProgress> initial() => [
    for (final step in ConnectSessionProgressStep.values)
      ConnectSessionProgress(
        step: step,
        state: step.index == 0 ? StepStatus.current : StepStatus.pending,
      ),
  ];

  /// [step] finished: everything up to it is done and the next step starts.
  /// Finishing the last step leaves every step done.
  static List<ConnectSessionProgress> completed(
    ConnectSessionProgressStep step,
  ) => [
    for (final s in ConnectSessionProgressStep.values)
      ConnectSessionProgress(
        step: s,
        state: s.index <= step.index
            ? StepStatus.done
            : s.index == step.index + 1
            ? StepStatus.current
            : StepStatus.pending,
      ),
  ];

  /// [step] failed: earlier steps stay done, later ones never started.
  static List<ConnectSessionProgress> failed(ConnectSessionProgressStep step) =>
      [
        for (final s in ConnectSessionProgressStep.values)
          ConnectSessionProgress(
            step: s,
            state: s.index < step.index
                ? StepStatus.done
                : s.index == step.index
                ? StepStatus.failed
                : StepStatus.pending,
          ),
      ];
}
