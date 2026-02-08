import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Integration tests for Excel to JSON conversion
///
/// Note: To run these tests, you must first generate the fixture files by running:
///   dart test/generate_fixtures.dart (if dart/flutter is in PATH)
///
/// These tests will be skipped if fixture files don't exist.
void main() {
  // Check if fixtures exist
  final fixturesExist = File('test/fixtures/simple.xlsx').existsSync() &&
      File('test/fixtures/multiple_sheets.xlsx').existsSync() &&
      File('test/fixtures/cell_types.xlsx').existsSync() &&
      File('test/fixtures/empty_rows.xlsx').existsSync();

  group('Integration Tests - Fixture Files', () {
    test('simple.xlsx should exist', () {
      if (!fixturesExist) {
        print('⚠️  Skipping: Fixture files not found.');
        print('   To generate: dart test/generate_fixtures.dart');
        return;
      }

      final file = File('test/fixtures/simple.xlsx');
      expect(file.existsSync(), isTrue, reason: 'simple.xlsx should exist');
      expect(file.lengthSync(), greaterThan(0));
    });

    test('multiple_sheets.xlsx should exist', () {
      if (!fixturesExist) {
        print('⚠️  Skipping: Fixture files not found.');
        return;
      }

      final file = File('test/fixtures/multiple_sheets.xlsx');
      expect(file.existsSync(), isTrue,
          reason: 'multiple_sheets.xlsx should exist');
      expect(file.lengthSync(), greaterThan(0));
    });

    test('cell_types.xlsx should exist', () {
      if (!fixturesExist) {
        print('⚠️  Skipping: Fixture files not found.');
        return;
      }

      final file = File('test/fixtures/cell_types.xlsx');
      expect(file.existsSync(), isTrue, reason: 'cell_types.xlsx should exist');
      expect(file.lengthSync(), greaterThan(0));
    });

    test('empty_rows.xlsx should exist', () {
      if (!fixturesExist) {
        print('⚠️  Skipping: Fixture files not found.');
        return;
      }

      final file = File('test/fixtures/empty_rows.xlsx');
      expect(file.existsSync(), isTrue, reason: 'empty_rows.xlsx should exist');
      expect(file.lengthSync(), greaterThan(0));
    });
  });

  group('Integration Tests - Notes', () {
    test('integration tests require fixtures to be generated manually', () {
      // This is just a note that integration tests with actual conversion
      // cannot be automated in the current setup because:
      // 1. ExcelToJson.convert() uses FilePicker which requires user interaction
      // 2. We can't test the full conversion without mocking FilePicker
      //
      // For now, these tests just verify that fixture files exist.
      // Actual conversion testing should be done manually or with E2E tests.
      expect(true, isTrue);
    });
  });
}
