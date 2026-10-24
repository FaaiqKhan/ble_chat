abstract class ConnectSessionEvent {}

final class ConnectChatSessionEvent extends ConnectSessionEvent {}

final class DisconnectChatSessionEvent extends ConnectSessionEvent {}
