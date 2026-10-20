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
  });

  /// The room name the user typed.
  final String query;

  /// Rooms found so far with that name, one per host.
  final List<FoundRoom> rooms;
  final ScanSessionStatus status;
  final String? errorMessage;

  ScanSessionState copyWith({
    String? query,
    List<FoundRoom>? rooms,
    ScanSessionStatus? status,
    String? errorMessage,
  }) {
    return ScanSessionState(
      query: query ?? this.query,
      rooms: rooms ?? this.rooms,
      status: status ?? this.status,
      // Cleared whenever a new status doesn't bring one.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [query, rooms, status, errorMessage];
}
