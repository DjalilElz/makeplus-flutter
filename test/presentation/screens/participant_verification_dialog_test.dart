import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makeplus/presentation/screens/organizer_badge_controller/participant_verification_result_screen.dart';
import 'package:makeplus/presentation/widgets/stats/stats_widgets.dart';

/// Opens the dialog from a button, as the scanner screen does.
Future<void> _open(
  WidgetTester tester,
  Map<String, dynamic> data, {
  Future<void> Function(String decision)? onDecision,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () => ParticipantVerificationDialog.show(context, data,
              onDecision: onDecision),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final registered = <String, dynamic>{
    'full_name': 'Amina Benali',
    'email': 'amina@example.com',
    'badge_id': 'USER-1',
    'paid_items': [
      {'type': 'session', 'title': 'Atelier Doppler', 'amount_paid': 1000.0},
    ],
    'registered': true,
    'scan_id': 42,
  };

  group('ParticipantVerificationDialog', () {
    testWidgets('records "Laisser entrer" and closes', (tester) async {
      final decisions = <String>[];
      await _open(tester, registered, onDecision: (d) async => decisions.add(d));

      expect(find.text('Amina Benali'), findsOneWidget);
      expect(find.text('Atelier Doppler'), findsOneWidget);
      await tester.tap(find.text('Laisser entrer'));
      await tester.pumpAndSettle();

      expect(decisions, ['granted']);
      expect(find.text('Laisser entrer'), findsNothing); // dialog closed
    });

    testWidgets('records "Refuser l\'accès"', (tester) async {
      final decisions = <String>[];
      await _open(tester, registered, onDecision: (d) async => decisions.add(d));
      await tester.tap(find.text("Refuser l'accès"));
      await tester.pumpAndSettle();
      expect(decisions, ['denied']);
    });

    testWidgets('a failed save keeps the dialog open with an error, retry works',
        (tester) async {
      var calls = 0;
      await _open(tester, registered, onDecision: (d) async {
        calls++;
        if (calls == 1) throw Exception('network');
      });

      await tester.tap(find.text('Laisser entrer'));
      await tester.pumpAndSettle();
      expect(find.textContaining("n'a pas pu être enregistrée"), findsOneWidget);
      expect(find.text('Laisser entrer'), findsOneWidget);

      await tester.tap(find.text('Laisser entrer'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Laisser entrer'), findsNothing);
    });

    testWidgets('"Fermer sans décision" closes without recording', (tester) async {
      final decisions = <String>[];
      await _open(tester, registered, onDecision: (d) async => decisions.add(d));
      await tester.tap(find.text('Fermer sans décision'));
      await tester.pumpAndSettle();
      expect(decisions, isEmpty);
      expect(find.text('Amina Benali'), findsNothing);
    });

    testWidgets('not registered: warning shown, decision still possible',
        (tester) async {
      final decisions = <String>[];
      await _open(
        tester,
        {
          'full_name': 'Karim Haddad',
          'paid_items': <dynamic>[],
          'registered': false,
          'message': "Ce participant n'est pas inscrit à cet événement.",
          'scan_id': 7,
        },
        onDecision: (d) async => decisions.add(d),
      );
      expect(find.text("Ce participant n'est pas inscrit à cet événement."),
          findsOneWidget);
      await tester.tap(find.text("Refuser l'accès"));
      await tester.pumpAndSettle();
      expect(decisions, ['denied']);
    });

    testWidgets('without scan_id only "Fermer" is offered', (tester) async {
      await _open(tester, {...registered, 'scan_id': null},
          onDecision: (d) async {});
      expect(find.text('Laisser entrer'), findsNothing);
      expect(find.text('Fermer'), findsOneWidget);
    });
  });

  group('HourlyBarsCard', () {
    testWidgets('shows the peak line and one label per hour', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: HourlyBarsCard(
            hourly: {
              'labels': ['10h', '11h', '12h'],
              'counts': [1, 38, 4],
            },
            peak: {'label': '11h–12h', 'count': 38},
            unit: 'scan',
          ),
        ),
      ));
      expect(find.text('Pointe : 11h–12h (38 scans)'), findsOneWidget);
      expect(find.text('10h'), findsOneWidget);
      expect(find.text('12h'), findsOneWidget);
    });

    testWidgets('renders nothing without data', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HourlyBarsCard(hourly: null, peak: null, unit: 'scan')),
      ));
      expect(find.text("Aujourd'hui, par heure"), findsNothing);
      expect(HourlyBarsCard.hasData(null), isFalse);
    });
  });
}
