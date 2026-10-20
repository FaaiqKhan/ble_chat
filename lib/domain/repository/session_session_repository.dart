import 'package:ble_chat/domain/entities/scanner_event.dart';

abstract class ScanSessionRepository {
  /// [query] is what the user typed: part of the room name or its code.
  Future<void> startScanning(String query);

  Future<void> stopScanning();

  Stream<ScannerEvent> scanSessionEvents();
}
