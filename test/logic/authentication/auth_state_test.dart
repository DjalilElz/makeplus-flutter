import 'package:flutter_test/flutter_test.dart';

import 'package:makeplus/data/models/user_model.dart';
import 'package:makeplus/logic/authentication/auth_state.dart';

void main() {
  group('AuthState.copyWith', () {
    const event = EventModel(id: 'evt-1', name: 'Test Event');

    test('event survives an unrelated copyWith call', () {
      const state = AuthState(event: event);
      final next = state.copyWith(status: AuthStatus.loading);
      expect(next.event, event);
    });

    test('clearEvent: true nulls out a previously-set event', () {
      const state = AuthState(event: event);
      final next = state.copyWith(clearEvent: true);
      expect(next.event, isNull);
    });

    test(
        'passing event: null without clearEvent keeps the old event '
        '(the ?? pitfall clearEvent exists to bypass)', () {
      const state = AuthState(event: event);
      final next = state.copyWith();
      expect(next.event, event);
    });
  });
}
