import 'dart:async';

import 'package:ble_chat/domain/entities/connect_event.dart';
import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:ble_chat/domain/repository/connect_session_repository.dart';
import 'package:flutter/services.dart';

class ConnectSessionRepositoryImpl implements ConnectSessionRepository {
  static const _eventChannel = EventChannel("connect/events");
  static const _methodChannel = MethodChannel("connect/methods");

  @override
  Future<void> connect(FoundRoom room, String code) => _methodChannel
      .invokeMethod("connect", {"address": room.address, "authCode": code});

  @override
  Future<void> disconnect() => _methodChannel.invokeMethod("disconnect");

  /// Native failures arrive as stream errors; they are turned into events so
  /// the listener handles every outcome in one place.
  @override
  Stream<ConnectEvent> connectSessionEvents() => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic data) => ConnectEvent.fromMap(data))
      .transform(
        StreamTransformer<ConnectEvent, ConnectEvent>.fromHandlers(
          handleError: (error, _, sink) => sink.add(
            error is PlatformException
                ? ConnectEvent.fromError(error.code, error.message)
                : const ConnectFailedEvent(code: "unknown"),
          ),
        ),
      );
}
