// lib/logic/event/event_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/event_model.dart';

enum EventBlocStatus {
  initial,
  loading,
  loaded,
  error,
  eventSelected,
}

class EventState extends Equatable {
  final EventBlocStatus status;
  final List<EventModel> events;
  final EventModel? currentEvent;
  final List<UserEventAssignment> userAssignments;
  final String? errorMessage;

  const EventState({
    this.status = EventBlocStatus.initial,
    this.events = const [],
    this.currentEvent,
    this.userAssignments = const [],
    this.errorMessage,
  });

  // Get user's role for current event
  String? get currentRole {
    if (currentEvent == null) return null;

    try {
      return userAssignments
          .firstWhere((a) => a.eventId == currentEvent!.id && a.isActive)
          .role;
    } catch (e) {
      return null;
    }
  }

  // Check if user has access to current event
  bool get hasEventAccess {
    if (currentEvent == null) return false;
    return userAssignments.any(
      (a) => a.eventId == currentEvent!.id && a.isActive,
    );
  }

  EventState copyWith({
    EventBlocStatus? status,
    List<EventModel>? events,
    EventModel? currentEvent,
    List<UserEventAssignment>? userAssignments,
    String? errorMessage,
  }) {
    return EventState(
      status: status ?? this.status,
      events: events ?? this.events,
      currentEvent: currentEvent ?? this.currentEvent,
      userAssignments: userAssignments ?? this.userAssignments,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        events,
        currentEvent,
        userAssignments,
        errorMessage,
      ];
}
