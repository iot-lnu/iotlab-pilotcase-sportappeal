// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:idrott_app/main.dart';

void main() {
  testWidgets('App launch test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IdrrottApp());

    // Verify that the app shows the initial auth screen
    expect(find.text('REGISTER'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);

    // Verify app has the fitness icon
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });
}
