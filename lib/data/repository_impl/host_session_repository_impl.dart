import 'dart:async';

import 'package:ble_chat/domain/entities/advertiser_event.dart';
import 'package:ble_chat/domain/entities/host_session_progress.dart';
import 'package:ble_chat/domain/repository/host_session_repository.dart';
import 'package:flutter/services.dart';

class HostSessionRepositoryImpl implements HostSessionRepository {
  static const _eventChannel = EventChannel("bleAdvertiser/events");
  static const _methodChannel = MethodChannel("bleAdvertiser/methods");

  /// Native failures arrive as stream errors; they are turned into events so
  /// the listener handles every outcome in one place.
  @override
  Stream<AdvertiserEvent> hostSessionEvents() => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic data) => AdvertiserEvent.fromMap(data))
      .transform(
        StreamTransformer<AdvertiserEvent, AdvertiserEvent>.fromHandlers(
          handleError: (error, _, sink) => sink.add(
            error is PlatformException
                ? AdvertiserEvent.fromError(error.code, error.message)
                : const HostSessionFailedEvent(
                    step: HostSessionProgressStep.advertising,
                  ),
          ),
        ),
      );

  /// Returns once native has accepted the request; progress follows on
  /// [hostSessionEvents].
  @override
  Future<void> start(String roomName) =>
      _methodChannel.invokeMethod<void>("start", roomName);

  /// Returns once native has accepted the request; progress follows on
  /// [hostSessionEvents].
  @override
  Future<void> stop() => _methodChannel.invokeMethod<void>("stop");
}
