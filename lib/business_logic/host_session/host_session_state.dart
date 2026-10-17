import 'package:ble_chat/presentation/screens/host_screen/host_screen.dart';
import 'package:equatable/equatable.dart';

enum HostSessionStatus { idle, starting, hosting, closing, closed, failed }

class HostSessionState extends Equatable {
  const HostSessionState({
    required this.roomName,
    required this.code,
    required this.maxPeople,
    this.participants = const [],
    this.status = HostSessionStatus.idle,
    this.startStep = 0,
    this.failedStep,
  });

  final String roomName;
  final String code;
  final int maxPeople;
  final List<HostParticipant> participants;
  final HostSessionStatus status;

  /// While starting: index of the step in progress (0 = Bluetooth ready,
  /// 1 = creating the room service, 2 = advertising).
  final int startStep;

  /// While failed: index of the step that failed.
  final int? failedStep;

  HostSessionState copyWith({
    List<HostParticipant>? participants,
    HostSessionStatus? status,
    int? startStep,
    int? failedStep,
  }) => HostSessionState(
    roomName: roomName,
    code: code,
    maxPeople: maxPeople,
    participants: participants ?? this.participants,
    status: status ?? this.status,
    startStep: startStep ?? this.startStep,
    failedStep: failedStep ?? this.failedStep,
  );

  void addParticipant(HostParticipant participant) =>
      participants.add(participant);

  void removeParticipant(String name) =>
      participants.retainWhere((p) => p.name == name);

  @override
  List<Object?> get props => [
    roomName,
    code,
    maxPeople,
    participants,
    status,
    startStep,
    failedStep,
  ];
}
