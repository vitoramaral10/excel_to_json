import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Excel to JSON app should load correctly',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExcelToJsonApp());

    // Verify that the app loads with the correct title
    expect(find.text('Excel to JSON Converter'), findsOneWidget);

    // Verify that the convert button is present
    expect(find.text('Select Excel File & Convert'), findsOneWidget);

    // Verify that the configuration options are present
    expect(find.text('Configuration'), findsOneWidget);
    expect(find.text('Include Empty Rows'), findsOneWidget);
    expect(find.text('Verbose Logging'), findsOneWidget);

    // Verify that the placeholder message is shown initially
    expect(find.text('No Excel file converted yet'), findsOneWidget);
  });

  testWidgets('Configuration switches should work',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ExcelToJsonApp());

    // Find the switches
    final emptyRowsSwitch = find.byType(Switch).first;
    final verboseSwitch = find.byType(Switch).last;

    // Verify initial state (should be false)
    Switch emptyRowsSwitchWidget = tester.widget(emptyRowsSwitch);
    Switch verboseSwitchWidget = tester.widget(verboseSwitch);

    expect(emptyRowsSwitchWidget.value, false);
    expect(verboseSwitchWidget.value, false);

    // Tap the switches to toggle them
    await tester.tap(emptyRowsSwitch);
    await tester.pump();

    await tester.tap(verboseSwitch);
    await tester.pump();

    // Verify they are now true
    emptyRowsSwitchWidget = tester.widget(emptyRowsSwitch);
    verboseSwitchWidget = tester.widget(verboseSwitch);

    expect(emptyRowsSwitchWidget.value, true);
    expect(verboseSwitchWidget.value, true);
  });
}
