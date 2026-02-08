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

    test('should create config with partial options', () {
      const config = ExcelToJsonConfig(
        includeEmptyRows: true,
      );

      expect(config.includeEmptyRows, true);
      expect(config.useDateTimeStrings, true); // default
      expect(config.verbose, false); // default
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

    test('should format exception string correctly with cause', () {
      const cause = FormatException('Invalid format');
      const exception = ExcelToJsonException('Conversion failed', cause);

      final exceptionString = exception.toString();
      expect(exceptionString, startsWith('ExcelToJsonException: '));
      expect(exceptionString, contains('Conversion failed'));
      expect(exceptionString, contains('Caused by:'));
      expect(exceptionString, contains('FormatException'));
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

    test('should accept all configuration combinations', () {
      const configs = [
        ExcelToJsonConfig(includeEmptyRows: true),
        ExcelToJsonConfig(useDateTimeStrings: false),
        ExcelToJsonConfig(verbose: true),
        ExcelToJsonConfig(
          includeEmptyRows: true,
          useDateTimeStrings: false,
          verbose: true,
        ),
      ];

      for (final config in configs) {
        final converter = ExcelToJson(config: config);
        expect(converter, isNotNull);
        expect(converter.config, equals(config));
      }
    });

    // Note: Testing the convert() method would require mocking file_picker
    // and creating test Excel files, which is beyond the scope of unit tests.
    // Integration tests would be more appropriate for testing the full conversion process.
    // See integration_test.dart for end-to-end testing with actual Excel files.
  });

  group('ExcelToJson - Error Handling', () {
    test('should be an instance of Exception', () {
      const exception = ExcelToJsonException('Test');
      expect(exception, isA<Exception>());
    });

    test('should preserve exception type when rethrowing', () {
      const original = ExcelToJsonException('Original error');
      const wrapped = ExcelToJsonException('Wrapped error', original);

      expect(wrapped.cause, equals(original));
      expect(wrapped.cause, isA<ExcelToJsonException>());
    });
  });

  group('ExcelToJsonConfig - Edge Cases', () {
    test('should handle null dateFormat correctly', () {
      const config = ExcelToJsonConfig(
        useDateTimeStrings: false,
      );

      expect(config.dateFormat, isNull);
      expect(config.useDateTimeStrings, false);
    });

    test('should be const constructible', () {
      const config1 = ExcelToJsonConfig();
      const config2 = ExcelToJsonConfig();

      // Both should be the same instance since they're const
      expect(identical(config1, config2), true);
    });

    test('should allow custom date format with useDateTimeStrings true', () {
      const config = ExcelToJsonConfig(
        dateFormat: 'dd/MM/yyyy',
      );

      expect(config.dateFormat, 'dd/MM/yyyy');
      expect(config.useDateTimeStrings, true);
    });
  });
}
