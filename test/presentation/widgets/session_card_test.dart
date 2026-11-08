import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makeplus/data/models/room_model.dart';
import 'package:makeplus/presentation/widgets/cards/session_card.dart';

// The last session of a real programme ("Clôture du congrès") has an empty
// speaker name; its card used to throw "RangeError (index): Invalid value:
// Valid value range is empty: 0" (first letter of "") and render as a red box.
Map<String, dynamic> _session({
  String speaker = '',
  String endTime = '2026-10-30T16:30:00+01:00',
}) =>
    {
      'id': 'b2c1',
      'title': 'Clôture du congrès',
      'description': '',
      'start_time': '2026-10-30T16:00:00+01:00',
      'end_time': endTime,
      'room': 'r1',
      'room_name': 'Salle Bab Ezzouar',
      'event': 'e1',
      'speaker_name': speaker,
      'speaker_title': '',
      'theme': '',
      'status': 'pas_encore',
      'session_type': 'conference',
      'is_paid': false,
      'is_live': false,
    };

Future<void> _pump(WidgetTester tester, SessionModel session) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SessionCard(session: session, typeLabel: 'Conférence'),
      ),
    ),
  ));
}

void main() {
  test('blank texts from the API become null', () {
    final s = SessionModel.fromJson(_session(speaker: '  '));
    expect(s.speakerName, isNull);
    expect(s.speakerTitle, isNull);
    expect(s.theme, isNull);
    expect(s.description, isNull);
  });

  testWidgets('a session without a speaker renders (no RangeError)',
      (tester) async {
    await _pump(tester, SessionModel.fromJson(_session()));
    expect(tester.takeException(), isNull);
    expect(find.text('Clôture du congrès'), findsOneWidget);
    expect(find.text('Conférence'), findsOneWidget); // type chip still shown
  });

  testWidgets('a session with a speaker shows the initial', (tester) async {
    await _pump(tester, SessionModel.fromJson(_session(speaker: 'L. Boudjit')));
    expect(tester.takeException(), isNull);
    expect(find.text('L'), findsOneWidget);
  });

  testWidgets('a past session never started shows "Terminé"', (tester) async {
    await _pump(tester, SessionModel.fromJson(_session()));
    expect(find.text('Terminé'), findsOneWidget);
  });

  testWidgets('a future session not started shows "Pas encore"',
      (tester) async {
    final future = DateTime.now().add(const Duration(days: 30));
    await _pump(
      tester,
      SessionModel.fromJson(_session(endTime: future.toIso8601String())),
    );
    expect(find.text('Pas encore'), findsOneWidget);
  });
}
