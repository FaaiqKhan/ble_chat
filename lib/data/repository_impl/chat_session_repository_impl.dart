import 'package:ble_chat/domain/repository/chat_session_repository.dart';
import 'package:flutter/services.dart';

class ChatSessionRepositoryImpl implements ChatSessionRepository {
  // static const _eventChannel = EventChannel("connect/events");
  static const _methodChannel = MethodChannel("connect/methods");

  @override
  Future<void> connect(String roomName, String code) => _methodChannel
      .invokeMethod("connect", {"roomName": roomName, "authCode": code});

  @override
  Future<void> disconnect() => _methodChannel.invokeMethod("disconnect");
}
