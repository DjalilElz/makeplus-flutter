// lib/logic/event/event_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/models/event_model.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository eventRepository;

  EventBloc({required this.eventRepository}) : super(const EventState()) {
    on<EventsFetchRequested>(_onEventsFetchRequested);
    on<EventSelectRequested>(_onEventSelectRequested);
    on<UserEventsFetchRequested>(_onUserEventsFetchRequested);
    on<EventCreateRequested>(_onEventCreateRequested);
  }

  Future<void> _onEventsFetchRequested(
    EventsFetchRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(status: EventBlocStatus.loading));

    try {
      final events = await eventRepository.getEvents();

      // Try to restore last selected event
      final prefs = await SharedPreferences.getInstance();
      final lastEventId = prefs.getString('last_event_id');

      EventModel? currentEvent;
      if (lastEventId != null && events.isNotEmpty) {
        try {
          currentEvent = events.firstWhere((e) => e.id == lastEventId);
        } catch (e) {
          // Event not found, will select first available
        }
      }

      // If no saved event, select first active or upcoming event
      if (currentEvent == null && events.isNotEmpty) {
        try {
          currentEvent = events.firstWhere(
            (e) => e.isActive() || e.isUpcoming(),
          );
        } catch (e) {
          // No active/upcoming events, select first one
          currentEvent = events.first;
        }
      }

      emit(state.copyWith(
        status: EventBlocStatus.loaded,
        events: events,
        currentEvent: currentEvent,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EventBlocStatus.error,
        errorMessage: 'Failed to fetch events: ${e.toString()}',
      ));
    }
  }

  Future<void> _onEventSelectRequested(
    EventSelectRequested event,
    Emitter<EventState> emit,
  ) async {
    try {
      final selectedEvent = state.events.firstWhere(
        (e) => e.id == event.eventId,
      );

      // Save selection to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_event_id', event.eventId);

      emit(state.copyWith(
        status: EventBlocStatus.eventSelected,
        currentEvent: selectedEvent,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EventBlocStatus.error,
        errorMessage: 'Failed to select event: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUserEventsFetchRequested(
    UserEventsFetchRequested event,
    Emitter<EventState> emit,
  ) async {
    try {
      final assignments = await eventRepository.getUserEventAssignments(
        event.userId,
      );

      emit(state.copyWith(
        userAssignments: assignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EventBlocStatus.error,
        errorMessage: 'Failed to fetch user events: ${e.toString()}',
      ));
    }
  }

  Future<void> _onEventCreateRequested(
    EventCreateRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(status: EventBlocStatus.loading));

    try {
      final newEvent = await eventRepository.createEvent(event.eventData);

      final updatedEvents = List<EventModel>.from(state.events)
        ..add(newEvent);

      emit(state.copyWith(
        status: EventBlocStatus.loaded,
        events: updatedEvents,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EventBlocStatus.error,
        errorMessage: 'Failed to create event: ${e.toString()}',
      ));
    }
  }
}
