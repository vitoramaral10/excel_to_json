import 'dart:convert';
import 'dart:developer';

import 'package:excel_to_json/excel_to_json.dart';

/// Advanced usage examples for the excel_to_json package
///
/// This file demonstrates various ways to use the package
/// in different scenarios and with different configurations.
class ExcelToJsonExamples {
  /// Example 1: Basic usage with default configuration
  ///
  /// This is the simplest way to use the package.
  /// Just create an instance and call convert().
  static Future<void> basicUsage() async {
    const converter = ExcelToJson();

    try {
      final jsonString = await converter.convert();
      if (jsonString != null) {
        log('Conversion successful!');
        log(jsonString);
      } else {
        log('No file selected.');
      }
    } on ExcelToJsonException catch (e) {
      log('Conversion error: ${e.message}');
    }
  }

  /// Example 2: Advanced configuration with all options
  ///
  /// This example shows how to use all available configuration options
  /// to customize the conversion process.
  static Future<void> advancedConfiguration() async {
    const config = ExcelToJsonConfig(
      includeEmptyRows: true, // Include rows with all empty cells
      useDateTimeStrings: false, // Keep date objects as native types
      verbose: true, // Enable detailed logging
    );

    const converter = ExcelToJson(config: config);

    try {
      final jsonString = await converter.convert();
      if (jsonString != null) {
        // Pretty log the JSON
        final data = jsonDecode(jsonString);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
        log(prettyJson);
      }
    } on ExcelToJsonException catch (e) {
      log('Error: ${e.message}');
      if (e.cause != null) {
        log('Caused by: ${e.cause}');
      }
    }
  }

  /// Example 3: Processing the JSON data after conversion
  ///
  /// This example shows how to work with the converted JSON data,
  /// accessing different worksheets and processing rows.
  static Future<void> processingJsonData() async {
    const converter = ExcelToJson();

    try {
      final jsonString = await converter.convert();
      if (jsonString == null) {
        log('No file selected');
        return;
      }

      // Parse the JSON string
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Iterate through all worksheets
      for (final entry in data.entries) {
        final sheetName = entry.key;
        final rows = entry.value as List<dynamic>;

        log('Processing worksheet: $sheetName');
        log('Total rows: ${rows.length}');

        // Process each row
        for (int i = 0; i < rows.length; i++) {
          final row = rows[i] as Map<String, dynamic>;
          log('Row ${i + 1}: $row');

          // Access specific columns
          for (final columnEntry in row.entries) {
            final columnName = columnEntry.key;
            final cellValue = columnEntry.value;
            log('  $columnName: $cellValue (${cellValue.runtimeType})');
          }
        }
        log('---');
      }
    } on ExcelToJsonException catch (e) {
      log('Conversion failed: ${e.message}');
    } catch (e) {
      log('Unexpected error: $e');
    }
  }

  /// Example 4: Error handling with detailed information
  ///
  /// This example demonstrates comprehensive error handling
  /// and how to extract useful information from exceptions.
  static Future<void> errorHandlingExample() async {
    const config = ExcelToJsonConfig(verbose: true);
    const converter = ExcelToJson(config: config);

    try {
      final jsonString = await converter.convert();

      if (jsonString != null) {
        // Validate JSON structure
        final data = jsonDecode(jsonString);

        if (data is Map<String, dynamic>) {
          if (data.isEmpty) {
            log('Warning: Excel file contains no data');
          } else {
            log('Success: Converted ${data.keys.length} worksheet(s)');

            // Count total rows across all sheets
            int totalRows = 0;
            for (final sheet in data.values) {
              if (sheet is List) {
                totalRows += sheet.length;
              }
            }
            log('Total data rows: $totalRows');
          }
        } else {
          log('Warning: Unexpected JSON structure');
        }
      } else {
        log('Info: No file was selected for conversion');
      }
    } on ExcelToJsonException catch (e) {
      // Handle package-specific exceptions
      log('Excel to JSON Error:');
      log('  Message: ${e.message}');

      if (e.cause != null) {
        log('  Root cause: ${e.cause}');
        log('  Cause type: ${e.cause.runtimeType}');
      }

      // Log the full exception for debugging
      log('  Full exception: $e');
    } on FormatException catch (e) {
      // Handle JSON parsing errors
      log('JSON Format Error: ${e.message}');
    } catch (e) {
      // Handle any other unexpected errors
      log('Unexpected error: $e');
      log('Error type: ${e.runtimeType}');
    }
  }

  /// Example 5: Working with different data types
  ///
  /// This example shows how different Excel cell types
  /// are converted to Dart/JSON types.
  static Future<void> dataTypesExample() async {
    const converter = ExcelToJson();

    try {
      final jsonString = await converter.convert();
      if (jsonString == null) return;

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      for (final entry in data.entries) {
        final sheetName = entry.key;
        final rows = entry.value as List<dynamic>;

        log('Data types in worksheet: $sheetName');

        for (final row in rows) {
          if (row is Map<String, dynamic>) {
            for (final cellEntry in row.entries) {
              final columnName = cellEntry.key;
              final cellValue = cellEntry.value;
              final valueType = cellValue.runtimeType;

              String typeDescription;
              if (cellValue is String) {
                typeDescription = 'Text/String';
              } else if (cellValue is int) {
                typeDescription = 'Integer';
              } else if (cellValue is double) {
                typeDescription = 'Decimal/Double';
              } else if (cellValue is bool) {
                typeDescription = 'Boolean';
              } else if (cellValue == null) {
                typeDescription = 'Empty/Null';
              } else {
                typeDescription = 'Other ($valueType)';
              }

              log('  $columnName: "$cellValue" -> $typeDescription');
            }
            break; // Only show first row as example
          }
        }
        log('---');
      }
    } on ExcelToJsonException catch (e) {
      log('Error: ${e.message}');
    }
  }

  /// Example 6: Batch processing multiple configurations
  ///
  /// This example shows how to convert the same file
  /// with different configurations and compare results.
  static Future<void> batchProcessingExample() async {
    final configs = [
      const ExcelToJsonConfig(
        includeEmptyRows: false,
        useDateTimeStrings: true,
      ),
      const ExcelToJsonConfig(
        includeEmptyRows: true,
        useDateTimeStrings: true,
      ),
      const ExcelToJsonConfig(
        includeEmptyRows: false,
        useDateTimeStrings: false,
      ),
    ];

    log('Batch processing with different configurations:');

    for (int i = 0; i < configs.length; i++) {
      final config = configs[i];
      final converter = ExcelToJson(config: config);

      log('\nConfiguration ${i + 1}:');
      log('  Include empty rows: ${config.includeEmptyRows}');
      log('  Use date/time strings: ${config.useDateTimeStrings}');

      try {
        final jsonString = await converter.convert();
        if (jsonString != null) {
          final data = jsonDecode(jsonString);
          final size = jsonString.length;

          log('  Result: Success');
          log('  JSON size: $size characters');

          if (data is Map<String, dynamic>) {
            int totalRows = 0;
            for (final sheet in data.values) {
              if (sheet is List) totalRows += sheet.length;
            }
            log('  Total rows: $totalRows');
          }
        } else {
          log('  Result: No file selected');
          break; // Don't continue if user cancels
        }
      } on ExcelToJsonException catch (e) {
        log('  Result: Error - ${e.message}');
      }
    }
  }
}
