import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:makeplus/main.dart';
import 'package:makeplus/presentation/screens/splash/splash_screen.dart';

void main() {
  setUp(() {
    // DjangoAuthService reads SharedPreferences on construction.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MakePlusApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Splash runs a 2.5s animation and a 2.5s delayed navigation. Let both
    // drain, otherwise teardown asserts on pending timers.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
