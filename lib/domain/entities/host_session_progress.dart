enum StepStatus { pending, current, done, failed }

enum HostSessionProgressStep { bluetooth, service, advertising }

class HostSessionProgress {
  const HostSessionProgress({required this.step, required this.state});

  final HostSessionProgressStep step;
  final StepStatus state;

  String get label => switch (step) {
    HostSessionProgressStep.bluetooth => "Bluetooth ready",
    HostSessionProgressStep.service => "Creating room service",
    HostSessionProgressStep.advertising => "Advertising to nearby devices",
  };

  /// Every step pending except the first, which is in progress.
  static List<HostSessionProgress> initial() => [
    for (final step in HostSessionProgressStep.values)
      HostSessionProgress(
        step: step,
        state: step.index == 0 ? StepStatus.current : StepStatus.pending,
      ),
  ];

  /// [step] finished: everything up to it is done and the next step starts.
  /// Finishing the last step leaves every step done.
  static List<HostSessionProgress> completed(HostSessionProgressStep step) => [
    for (final s in HostSessionProgressStep.values)
      HostSessionProgress(
        step: s,
        state: s.index <= step.index
            ? StepStatus.done
            : s.index == step.index + 1
            ? StepStatus.current
            : StepStatus.pending,
      ),
  ];

  /// [step] failed: earlier steps stay done, later ones never started.
  static List<HostSessionProgress> failed(HostSessionProgressStep step) => [
    for (final s in HostSessionProgressStep.values)
      HostSessionProgress(
        step: s,
        state: s.index < step.index
            ? StepStatus.done
            : s.index == step.index
            ? StepStatus.failed
            : StepStatus.pending,
      ),
  ];
}
