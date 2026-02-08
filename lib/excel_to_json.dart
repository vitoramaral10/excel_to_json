import 'dart:convert';
import 'dart:developer';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Callback function for reporting conversion progress
///
/// [current] - The current item being processed
/// [total] - The total number of items to process
/// [message] - A descriptive message about the current operation
typedef ProgressCallback = void Function(
  int current,
  int total,
  String message,
);

/// Configuration options for Excel to JSON conversion
class ExcelToJsonConfig {
  /// Creates a new configuration instance with the specified options.
  ///
  /// [includeEmptyRows] - Whether to include rows where all cells are empty
  /// [useDateTimeStrings] - Whether to convert date/time values to strings
  /// [dateFormat] - Custom date format pattern (uses intl DateFormat)
  /// [verbose] - Whether to enable detailed logging during conversion
  /// [onProgress] - Optional callback to receive conversion progress updates
  /// [selectedWorksheets] - Optional list of worksheet names to convert.
  ///   If null or empty, all worksheets will be converted.
  const ExcelToJsonConfig({
    this.includeEmptyRows = false,
    this.useDateTimeStrings = true,
    this.dateFormat,
    this.verbose = false,
    this.onProgress,
    this.selectedWorksheets,
  });

  /// Whether to include empty rows in the output
  final bool includeEmptyRows;

  /// Whether to convert date/time values to ISO strings or keep original format
  final bool useDateTimeStrings;

  /// Custom date format pattern for formatting date values
  ///
  /// Uses the intl package's DateFormat patterns.
  /// Examples: 'yyyy-MM-dd', 'dd/MM/yyyy HH:mm:ss', 'MMM d, y'
  ///
  /// If null, dates will be converted using toString() when useDateTimeStrings is true.
  final String? dateFormat;

  /// Whether to log conversion progress
  final bool verbose;

  /// Optional callback to receive progress updates during conversion
  ///
  /// The callback will be invoked at key points during the conversion:
  /// - When starting to process a worksheet
  /// - Periodically during row processing
  /// - When completing a worksheet
  final ProgressCallback? onProgress;

  /// Optional list of worksheet names to convert
  ///
  /// If provided and not empty, only the worksheets with names in this list
  /// will be converted. If null or empty, all worksheets will be converted.
  ///
  /// Example: `selectedWorksheets: ['Sheet1', 'Products']`
  final List<String>? selectedWorksheets;
}

/// Exception thrown when Excel to JSON conversion fails
class ExcelToJsonException implements Exception {
  /// Creates a new exception with the specified message and optional underlying cause.
  ///
  /// [message] - The error message describing what went wrong
  /// [cause] - The underlying exception that caused this error
  const ExcelToJsonException(this.message, [this.cause]);

  /// The error message
  final String message;

  /// The underlying cause of the error
  final Object? cause;

  @override
  String toString() =>
      'ExcelToJsonException: $message${cause != null ? ' (Caused by: $cause)' : ''}';
}

/// A Flutter package that converts Excel (.xlsx) files to JSON format.
///
/// This package provides an easy way to read Excel files and convert them
/// to structured JSON data, making it simple to work with Excel data in
/// Flutter applications.
///
/// Example usage:
/// ```dart
/// final converter = ExcelToJson();
/// final jsonString = await converter.convert();
/// print(jsonString);
/// ```
class ExcelToJson {
  /// Creates a new instance of ExcelToJson with optional configuration.
  ///
  /// [config] - Configuration options for the conversion process.
  const ExcelToJson({this.config = const ExcelToJsonConfig()});

  /// Configuration options for the conversion
  final ExcelToJsonConfig config;

  /// Converts an Excel file to JSON format.
  ///
  /// Opens a file picker dialog to select an Excel file (.xlsx) and converts
  /// it to JSON format. Each worksheet becomes a top-level property in the
  /// resulting JSON object.
  ///
  /// Returns a JSON string representation of the Excel data, or null if
  /// no file was selected or an error occurred.
  ///
  /// Throws [ExcelToJsonException] if the conversion fails.
  ///
  /// Example:
  /// ```dart
  /// final converter = ExcelToJson();
  /// try {
  ///   final jsonString = await converter.convert();
  ///   if (jsonString != null) {
  ///     final data = jsonDecode(jsonString);
  ///     print(data);
  ///   }
  /// } catch (e) {
  ///   print('Conversion failed: $e');
  /// }
  /// ```
  Future<String?> convert() async {
    try {
      if (config.verbose) {
        log('Starting Excel to JSON conversion...');
      }

      final Excel? excel = await _getFile();

      if (excel == null) {
        if (config.verbose) {
          log('No file selected or failed to read file');
        }
        return null;
      }

      List<String> tables = _getTables(excel);
      
      // Filter worksheets if selectedWorksheets is specified
      if (config.selectedWorksheets != null &&
          config.selectedWorksheets!.isNotEmpty) {
        tables = tables
            .where((table) => config.selectedWorksheets!.contains(table))
            .toList();
        
        if (config.verbose) {
          log('Filtering to selected worksheets: ${config.selectedWorksheets!.join(', ')}');
        }
      }
      
      if (config.verbose) {
        log('Found ${tables.length} worksheet(s): ${tables.join(', ')}');
      }

      // Report initial progress
      config.onProgress?.call(0, tables.length, 'Starting conversion...');

      int index = 0;
      final Map<String, dynamic> json = {};
      int tableIndex = 0;

      for (final String table in tables) {
        tableIndex++;
        
        if (config.verbose) {
          log('Processing worksheet: $table ($tableIndex/${tables.length})');
        }

        // Report progress for starting this worksheet
        config.onProgress?.call(
          tableIndex - 1,
          tables.length,
          'Processing worksheet: $table',
        );

        List<Data?> keys = [];
        json.addAll({table: []});
        int processedRows = 0;

        final rows = excel.tables[table]?.rows ?? [];

        for (final List<Data?> row in rows) {
          try {
            if (index == 0) {
              keys = row;
              index++;
            } else {
              final Map<String, dynamic> temp = _getRows(keys, row);

              if (temp.isNotEmpty || config.includeEmptyRows) {
                json[table].add(temp);
                processedRows++;
                
                // Report progress periodically (every 100 rows)
                if (processedRows % 100 == 0) {
                  config.onProgress?.call(
                    tableIndex - 1,
                    tables.length,
                    'Processing worksheet: $table ($processedRows rows)',
                  );
                }
              }
            }
          } on Exception catch (ex) {
            final error =
                'Error processing row ${index + 1} in worksheet "$table": $ex';
            log(error);

            throw ExcelToJsonException(error, ex);
          }
        }

        if (config.verbose) {
          log('Processed $processedRows rows from worksheet: $table');
        }
        
        // Report progress for completing this worksheet
        config.onProgress?.call(
          tableIndex,
          tables.length,
          'Completed worksheet: $table ($processedRows rows)',
        );

        index = 0;
      }

      if (config.verbose) {
        log('Excel to JSON conversion completed successfully');
      }

      // Report final progress
      config.onProgress?.call(
        tables.length,
        tables.length,
        'Conversion complete',
      );

      return jsonEncode(json);
    } on ExcelToJsonException {
      rethrow;
    } on Exception catch (e) {
      final error = 'Failed to convert Excel to JSON: $e';
      log(error);
      throw ExcelToJsonException(error, e);
    }
  }

  /// Extracts row data and converts it to a Map using the provided keys.
  ///
  /// [keys] - The header row containing column names
  /// [row] - The data row to convert
  ///
  /// Returns a Map with column names as keys and cell values as values.
  Map<String, dynamic> _getRows(final List<Data?> keys, final List<Data?> row) {
    final Map<String, dynamic> temp = {};
    int index = 0;

    for (final Data? key in keys) {
      if (key != null && key.value != null) {
        final String columnName = key.value.toString();

        if (index < row.length &&
            row[index] != null &&
            row[index]!.value != null) {
          final value = row[index]!.value;
          temp[columnName] = _convertCellValue(value);
        } else {
          temp[columnName] = null;
        }

        index++;
      }
    }

    return temp;
  }

  /// Converts a cell value to the appropriate Dart type.
  ///
  /// [value] - The cell value to convert
  ///
  /// Returns the converted value in the appropriate Dart type.
  dynamic _convertCellValue(dynamic value) {
    switch (value) {
      case null:
        return null;
      case TextCellValue():
        return value.value;
      case FormulaCellValue():
        return value.formula;
      case IntCellValue():
        return value.value;
      case BoolCellValue():
        return value.value;
      case DoubleCellValue():
        return value.value;
      case DateCellValue():
        return _formatDateTime(
          DateTime(value.year, value.month, value.day),
        );
      case TimeCellValue():
        return _formatDateTime(
          DateTime(2000, 1, 1, value.hour, value.minute, value.second),
        );
      case DateTimeCellValue():
        return _formatDateTime(
          DateTime(
            value.year,
            value.month,
            value.day,
            value.hour,
            value.minute,
            value.second,
          ),
        );
      default:
        return value.toString();
    }
  }

  /// Formats a DateTime value based on configuration
  ///
  /// [dateTime] - The DateTime to format
  ///
  /// Returns a formatted string. Always returns a string to ensure JSON serialization works.
  String _formatDateTime(final DateTime dateTime) {
    // Always convert to string for JSON compatibility
    if (config.dateFormat != null) {
      try {
        final formatter = DateFormat(config.dateFormat);
        return formatter.format(dateTime);
      } on Exception catch (e) {
        if (config.verbose) {
          log('Warning: Failed to format date with pattern "${config.dateFormat}": $e');
        }
        // Fall back to ISO 8601 string if format fails
        return dateTime.toIso8601String();
      }
    }

    // Default formatting based on useDateTimeStrings
    if (config.useDateTimeStrings) {
      return dateTime.toIso8601String();
    } else {
      // Even when useDateTimeStrings is false, we must return a string for JSON
      // Use a simple format instead of ISO 8601
      return dateTime.toString();
    }
  }

  /// Extracts the names of all worksheets from the Excel file.
  ///
  /// [excel] - The Excel file object
  ///
  /// Returns a list of worksheet names.
  List<String> _getTables(final Excel excel) => excel.tables.keys.toList();

  /// Opens a file picker dialog to select an Excel file.
  ///
  /// Returns an Excel object if a file was successfully selected and loaded,
  /// otherwise returns null.
  ///
  /// Throws [ExcelToJsonException] if file loading fails.
  Future<Excel?> _getFile() async {
    try {
      final FilePickerResult? file = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        dialogTitle: 'Select Excel file to convert',
      );

      if (file != null && file.files.isNotEmpty) {
        final platformFile = file.files.first;

        if (platformFile.bytes == null) {
          throw const ExcelToJsonException('Failed to read file data');
        }

        final Uint8List bytes = platformFile.bytes!;

        if (config.verbose) {
          log('Selected file: ${platformFile.name} (${bytes.length} bytes)');
        }

        return Excel.decodeBytes(bytes);
      } else {
        return null;
      }
    } on Exception catch (e) {
      if (e is ExcelToJsonException) {
        rethrow;
      }

      final error = 'Failed to load Excel file: $e';
      log(error);
      throw ExcelToJsonException(error, e);
    }
  }
}
