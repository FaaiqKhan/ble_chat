import 'package:ble_chat/domain/entities/connect_event.dart';

abstract class ConnectSessionEvent {}

final class ConnectChatSessionEvent extends ConnectSessionEvent {}

final class DisconnectChatSessionEvent extends ConnectSessionEvent {}

/// Wraps something native reported so the bloc handles it like any other event.
/// Added by the bloc itself, not by the UI.
final class ConnectEventReceived extends ConnectSessionEvent {
  ConnectEventReceived(this.event);

  final ConnectEvent event;
}
