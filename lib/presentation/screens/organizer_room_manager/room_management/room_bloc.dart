// lib/logic/organizer/room_management/room_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:makeplus/data/models/room_model.dart';
import 'package:makeplus/data/repositories/room_repository.dart';

import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final RoomRepository roomRepository;

  RoomBloc({required this.roomRepository}) : super(const RoomState()) {
    on<RoomsFetchRequested>(_onRoomsFetchRequested);
    on<RoomFetchRequested>(_onRoomFetchRequested);
    on<RoomCreateRequested>(_onRoomCreateRequested);
    on<RoomUpdateRequested>(_onRoomUpdateRequested);
    on<RoomDeleteRequested>(_onRoomDeleteRequested);
    on<SessionCreateRequested>(_onSessionCreateRequested);
    on<SessionUpdateRequested>(_onSessionUpdateRequested);
    on<SessionDeleteRequested>(_onSessionDeleteRequested);
  }

  Future<void> _onRoomsFetchRequested(
    RoomsFetchRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.loading));

    try {
      final rooms = await roomRepository.getRooms(eventId: event.eventId);
      emit(state.copyWith(
        status: RoomStatus.loaded,
        rooms: rooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to fetch rooms: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRoomFetchRequested(
    RoomFetchRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.loading));

    try {
      final room = await roomRepository.getRoom(event.roomId);
      emit(state.copyWith(
        status: RoomStatus.loaded,
        selectedRoom: room,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to fetch room: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRoomCreateRequested(
    RoomCreateRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.creating));

    try {
      final newRoom = await roomRepository.createRoom(event.roomData);
      final updatedRooms = List<RoomModel>.from(state.rooms)..add(newRoom);

      emit(state.copyWith(
        status: RoomStatus.created,
        rooms: updatedRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to create room: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRoomUpdateRequested(
    RoomUpdateRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.updating));

    try {
      final updatedRoom = await roomRepository.updateRoom(
        event.roomId,
        event.updates,
      );

      final updatedRooms = state.rooms.map((room) {
        return room.id == event.roomId ? updatedRoom : room;
      }).toList();

      emit(state.copyWith(
        status: RoomStatus.updated,
        rooms: updatedRooms,
        selectedRoom: updatedRoom,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to update room: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRoomDeleteRequested(
    RoomDeleteRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.deleting));

    try {
      await roomRepository.deleteRoom(event.roomId);

      final updatedRooms =
          state.rooms.where((room) => room.id != event.roomId).toList();

      emit(state.copyWith(
        status: RoomStatus.deleted,
        rooms: updatedRooms,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to delete room: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSessionCreateRequested(
    SessionCreateRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.creating));

    try {
      final newSession = await roomRepository.createSession(event.sessionData);

      // Update the room with the new session
      if (state.selectedRoom != null) {
        final updatedSessions = List<SessionModel>.from(
          state.selectedRoom!.sessions,
        )..add(newSession);

        final updatedRoom = RoomModel(
          id: state.selectedRoom!.id,
          name: state.selectedRoom!.name,
          description: state.selectedRoom!.description,
          capacity: state.selectedRoom!.capacity,
          eventId: state.selectedRoom!.eventId,
          sessions: updatedSessions,
          currentParticipants: state.selectedRoom!.currentParticipants,
          isActive: state.selectedRoom!.isActive,
        );

        emit(state.copyWith(
          status: RoomStatus.created,
          selectedRoom: updatedRoom,
        ));
      } else {
        emit(state.copyWith(status: RoomStatus.created));
      }
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to create session: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSessionUpdateRequested(
    SessionUpdateRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.updating));

    try {
      await roomRepository.updateSession(event.sessionId, event.updates);

      // Refresh the room data
      if (state.selectedRoom != null) {
        add(RoomFetchRequested(state.selectedRoom!.id));
      }
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to update session: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSessionDeleteRequested(
    SessionDeleteRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.deleting));

    try {
      await roomRepository.deleteSession(event.sessionId);

      // Refresh the room data
      if (state.selectedRoom != null) {
        add(RoomFetchRequested(state.selectedRoom!.id));
      }
    } catch (e) {
      emit(state.copyWith(
        status: RoomStatus.error,
        errorMessage: 'Failed to delete session: ${e.toString()}',
      ));
    }
  }
}
