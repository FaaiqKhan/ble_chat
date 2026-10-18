sealed class HostSessionEvent {}

final class StartHostingEvent extends HostSessionEvent {}

final class CloseRoomEvent extends HostSessionEvent {}

/// Leaves the "couldn't close" error and goes back to hosting.
final class DismissCloseErrorEvent extends HostSessionEvent {}

final class PeerJoinedEvent extends HostSessionEvent {}

final class PeerSignalStrengthEvent extends HostSessionEvent {}
