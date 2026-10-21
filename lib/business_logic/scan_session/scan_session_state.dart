import 'package:ble_chat/domain/entities/found_room.dart';
import 'package:equatable/equatable.dart';

enum ScanSessionStatus {
  idle,

  /// Searching. [ScanSessionState.rooms] fills up while this lasts.
  scanning,

  /// The search finished and found at least one room.
  scanned,
  notFound,
  failed,
  joining,
  joined,
}

class ScanSessionState extends Equatable {
  const ScanSessionState({
    this.query = "",
    this.rooms = const [],
    this.status = ScanSessionStatus.idle,
    this.errorMessage,
    this.isScanning = false,
  });

  /// The room name the user typed.
  final String query;

  /// Rooms found so far with that name, one per host.
  final List<FoundRoom> rooms;
  final ScanSessionStatus status;
  final String? errorMessage;

  /// Scanning for rooms.
  final bool isScanning;

  ScanSessionState copyWith({
    String? query,
    List<FoundRoom>? rooms,
    ScanSessionStatus? status,
    String? errorMessage,
    bool? isScanning,
  }) {
    return ScanSessionState(
      query: query ?? this.query,
      rooms: rooms ?? this.rooms,
      status: status ?? this.status,
      isScanning: isScanning ?? this.isScanning,
      // Cleared whenever a new status doesn't bring one.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [query, rooms, status, isScanning, errorMessage];
}
