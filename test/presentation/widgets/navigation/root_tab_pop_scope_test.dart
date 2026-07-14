import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makeplus/presentation/widgets/navigation/root_tab_pop_scope.dart';

void main() {
  group('RootTabPopScope', () {
    testWidgets('home screen at stack root shows exit confirmation on back',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: RootTabPopScope(
          homeRoute: '/home',
          isHome: true,
          child: Scaffold(body: Text('Home')),
        ),
      ));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Quitter l\'application'), findsOneWidget);
    });

    testWidgets(
        'non-home tab at stack root redirects to home instead of exiting',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/tab',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/tab':
              return MaterialPageRoute(
                builder: (_) => const RootTabPopScope(
                  homeRoute: '/home',
                  child: Scaffold(body: Text('Tab')),
                ),
              );
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Home')),
              );
          }
          return null;
        },
      ));

      expect(find.text('Tab'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tab'), findsNothing);
      expect(find.text('Quitter l\'application'), findsNothing);
    });

    testWidgets(
        'tab screen pushed on top of another screen just pops back normally',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RootTabPopScope(
                    homeRoute: '/home',
                    child: Scaffold(
                      appBar: AppBar(),
                      body: const Text('Tab'),
                    ),
                  ),
                ),
              ),
              child: const Text('Open Tab'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Tab'));
      await tester.pumpAndSettle();
      expect(find.text('Tab'), findsOneWidget);

      // Default AppBar back button is auto-shown because there is a
      // previous route to pop to (RootTabPopScope must not suppress it).
      expect(find.byType(BackButton), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Returns to the screen that pushed it -- not to home, and no
      // exit-app dialog.
      expect(find.text('Open Tab'), findsOneWidget);
      expect(find.text('Tab'), findsNothing);
      expect(find.text('Quitter l\'application'), findsNothing);
    });
  });
}
