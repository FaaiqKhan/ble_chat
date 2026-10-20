import 'package:ble_chat/domain/repository/join_room_repository.dart';
import 'package:flutter/services.dart';

class ScanRoomRepositoryImpl implements ScanRoomRepository {
  // static const _eventChannel = EventChannel("bleScanner/events");
  static const _methodChannel = MethodChannel("bleScanner/methods");

  @override
  Future<void> startScanning({required String name, required String code}) =>
      _methodChannel.invokeMethod("scan", {"roomName": name, "roomCode": code});

  @override
  Future<void> stopScanning() => _methodChannel.invokeMethod("stop");
}
