// lib/logic/organizer/room_management/room_event.dart

import 'package:equatable/equatable.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class RoomsFetchRequested extends RoomEvent {
  final String? eventId;

  const RoomsFetchRequested({this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class RoomFetchRequested extends RoomEvent {
  final String roomId;

  const RoomFetchRequested(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class RoomCreateRequested extends RoomEvent {
  final Map<String, dynamic> roomData;

  const RoomCreateRequested(this.roomData);

  @override
  List<Object?> get props => [roomData];
}

class RoomUpdateRequested extends RoomEvent {
  final String roomId;
  final Map<String, dynamic> updates;

  const RoomUpdateRequested(this.roomId, this.updates);

  @override
  List<Object?> get props => [roomId, updates];
}

class RoomDeleteRequested extends RoomEvent {
  final String roomId;

  const RoomDeleteRequested(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class SessionCreateRequested extends RoomEvent {
  final Map<String, dynamic> sessionData;

  const SessionCreateRequested(this.sessionData);

  @override
  List<Object?> get props => [sessionData];
}

class SessionUpdateRequested extends RoomEvent {
  final String sessionId;
  final Map<String, dynamic> updates;

  const SessionUpdateRequested(this.sessionId, this.updates);

  @override
  List<Object?> get props => [sessionId, updates];
}

class SessionDeleteRequested extends RoomEvent {
  final String sessionId;

  const SessionDeleteRequested(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}