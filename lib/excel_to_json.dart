/// Converts spreadsheets (.xlsx and .csv) to JSON or Dart maps, in pure Dart.
///
/// ```dart
/// import 'dart:io';
///
/// import 'package:excel_to_json/excel_to_json.dart';
///
/// final bytes = File('people.xlsx').readAsBytesSync();
/// final json = const ExcelToJson().toJson(bytes);
/// // {"Sheet1":[{"Name":"Ana","Age":30}]}
/// ```
library;

export 'src/config.dart';
export 'src/converter.dart';
export 'src/exception.dart';
