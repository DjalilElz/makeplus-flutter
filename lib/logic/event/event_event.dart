// lib/logic/event/event_event.dart

import 'package:equatable/equatable.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class EventsFetchRequested extends EventEvent {
  const EventsFetchRequested();
}

class EventSelectRequested extends EventEvent {
  final String eventId;

  const EventSelectRequested(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class UserEventsFetchRequested extends EventEvent {
  final String userId;

  const UserEventsFetchRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class EventCreateRequested extends EventEvent {
  final Map<String, dynamic> eventData;

  const EventCreateRequested(this.eventData);

  @override
  List<Object?> get props => [eventData];
}
