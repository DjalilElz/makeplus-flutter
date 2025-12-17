// lib/logic/organizer/room_management/room_state.dart

import 'package:equatable/equatable.dart';
import 'package:makeplus/data/models/room_model.dart';


enum RoomStatus {
  initial,
  loading,
  loaded,
  error,
  creating,
  created,
  updating,
  updated,
  deleting,
  deleted,
}

class RoomState extends Equatable {
  final RoomStatus status;
  final List<RoomModel> rooms;
  final RoomModel? selectedRoom;
  final String? errorMessage;

  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.selectedRoom,
    this.errorMessage,
  });

  RoomState copyWith({
    RoomStatus? status,
    List<RoomModel>? rooms,
    RoomModel? selectedRoom,
    String? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, selectedRoom, errorMessage];
}