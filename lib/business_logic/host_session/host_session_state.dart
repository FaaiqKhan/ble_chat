import 'package:ble_chat/domain/entities/host_session_progress.dart';
import 'package:ble_chat/presentation/screens/host/host_room_screen.dart';
import 'package:equatable/equatable.dart';

enum HostSessionStatus {
  idle,
  starting,
  hosting,
  closing,
  closed,
  failed,
  closeFailed,
}

class HostSessionState extends Equatable {
  const HostSessionState({
    required this.roomName,
    required this.code,
    required this.maxPeople,
    this.participants = const [],
    this.status = HostSessionStatus.idle,
    this.progress = const [],
    this.authCode = "",
  });

  final String roomName;
  final String code;
  final int maxPeople;
  final List<HostParticipant> participants;
  final HostSessionStatus status;
  final String authCode;

  /// The startup steps and where each one is. Empty until hosting starts.
  final List<HostSessionProgress> progress;

  HostSessionState copyWith({
    List<HostParticipant>? participants,
    HostSessionStatus? status,
    List<HostSessionProgress>? progress,
    String? authCode,
  }) => HostSessionState(
    roomName: roomName,
    code: code,
    maxPeople: maxPeople,
    participants: participants ?? this.participants,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    authCode: authCode ?? this.authCode,
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
    progress,
  ];
}
