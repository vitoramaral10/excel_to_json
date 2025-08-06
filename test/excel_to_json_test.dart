import 'package:excel_to_json/excel_to_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExcelToJsonConfig', () {
    test('should create default config', () {
      const config = ExcelToJsonConfig();

      expect(config.includeEmptyRows, false);
      expect(config.useDateTimeStrings, true);
      expect(config.dateFormat, null);
      expect(config.verbose, false);
    });

    test('should create custom config', () {
      const config = ExcelToJsonConfig(
        includeEmptyRows: true,
        useDateTimeStrings: false,
        dateFormat: 'yyyy-MM-dd',
        verbose: true,
      );

      expect(config.includeEmptyRows, true);
      expect(config.useDateTimeStrings, false);
      expect(config.dateFormat, 'yyyy-MM-dd');
      expect(config.verbose, true);
    });
  });

  group('ExcelToJsonException', () {
    test('should create exception with message only', () {
      const exception = ExcelToJsonException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.cause, null);
      expect(exception.toString(), 'ExcelToJsonException: Test error');
    });

    test('should create exception with message and cause', () {
      final cause = Exception('Original error');
      final exception = ExcelToJsonException('Test error', cause);

      expect(exception.message, 'Test error');
      expect(exception.cause, cause);
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('Caused by:'));
    });
  });

  group('ExcelToJson', () {
    test('should create instance with default config', () {
      const converter = ExcelToJson();

      expect(converter.config.includeEmptyRows, false);
      expect(converter.config.useDateTimeStrings, true);
      expect(converter.config.verbose, false);
    });

    test('should create instance with custom config', () {
      const config = ExcelToJsonConfig(
        includeEmptyRows: true,
        verbose: true,
      );
      const converter = ExcelToJson(config: config);

      expect(converter.config.includeEmptyRows, true);
      expect(converter.config.verbose, true);
    });

    // Note: Testing the convert() method would require mocking file_picker
    // and creating test Excel files, which is beyond the scope of unit tests.
    // Integration tests would be more appropriate for testing the full conversion process.
  });
}
