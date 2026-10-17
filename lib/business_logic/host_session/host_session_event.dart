sealed class HostSessionEvent {}

final class StartHostingEvent extends HostSessionEvent {}

final class CloseRoomEvent extends HostSessionEvent {}

final class PeerJoinedEvent extends HostSessionEvent {}

final class PeerSignalStrengthEvent extends HostSessionEvent {}
