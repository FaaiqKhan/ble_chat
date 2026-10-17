import 'package:ble_chat/presentation/screens/host_screen/host_screen.dart';
import 'package:equatable/equatable.dart';

class HostSessionState extends Equatable {
  const HostSessionState({
    required this.roomName,
    required this.code,
    required this.maxPeople,
    this.participants = const [],
  });

  final String roomName;
  final String code;
  final int maxPeople;
  final List<HostParticipant> participants;

  void addParticipant(HostParticipant participant) =>
      participants.add(participant);

  void removeParticipant(String name) =>
      participants.retainWhere((p) => p.name == name);

  @override
  List<Object?> get props => [roomName, code, maxPeople, participants];
}
