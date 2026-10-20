import 'dart:async';

import 'package:ble_chat/domain/entities/scanner_event.dart';
import 'package:ble_chat/domain/repository/session_session_repository.dart';
import 'package:flutter/services.dart';

class ScanSessionRepositoryImpl implements ScanSessionRepository {
  static const _eventChannel = EventChannel("bleScanner/events");
  static const _methodChannel = MethodChannel("bleScanner/methods");

  /// Returns once native accepted the request; the outcome follows on
  /// [scanSessionEvents].
  @override
  Future<void> startScanning(String query) =>
      _methodChannel.invokeMethod<void>("scan", query);

  @override
  Future<void> stopScanning() => _methodChannel.invokeMethod<void>("stop");

  /// Native failures arrive as stream errors; they are turned into events so
  /// the listener handles every outcome in one place.
  @override
  Stream<ScannerEvent> scanSessionEvents() => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic data) => ScannerEvent.fromMap(data))
      .transform(
        StreamTransformer<ScannerEvent, ScannerEvent>.fromHandlers(
          handleError: (error, _, sink) => sink.add(
            error is PlatformException
                ? ScannerEvent.fromError(error.code, error.message)
                : const ScannerFailedEvent(code: "unknown"),
          ),
        ),
      );
}
