import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';

void main() {
  testWidgets('Weather App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WeatherApp());

    // Verify that the app title is present.
    expect(find.text('Weather App'), findsWidgets);

    // Verify that the search field is present.
    expect(find.text('Enter City'), findsOneWidget);

    // Verify that the search icon is present.
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
