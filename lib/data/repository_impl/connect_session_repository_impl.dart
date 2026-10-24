import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/domain/repository/connect_session_repository.dart';
import 'package:flutter/services.dart';

class ConnectSessionRepositoryImpl implements ConnectSessionRepository {
  // static const _eventChannel = EventChannel("connect/events");
  static const _methodChannel = MethodChannel("connect/methods");

  @override
  Future<void> connect(FoundRoom room, String code) => _methodChannel
      .invokeMethod("connect", {"roomName": room.name, "authCode": code});

  @override
  Future<void> disconnect() => _methodChannel.invokeMethod("disconnect");

  @override
  Future<void> listenRoomSignal(FoundRoom room) {
    // TODO: implement listenRoomSignal
    throw UnimplementedError();
  }

  @override
  Future<void> updateConnectStatus(FoundRoom room) {
    // TODO: implement updateConnectStatus
    throw UnimplementedError();
  }
}
