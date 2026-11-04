// Converts an .xlsx or .csv file to JSON and prints it.
//
//   dart run example/excel_to_json_example.dart people.xlsx
import 'dart:io';

import 'package:excel_to_json/excel_to_json.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run example/excel_to_json_example.dart <file.xlsx|file.csv>',
    );
    exitCode = 64;
    return;
  }

  try {
    final bytes = File(args.single).readAsBytesSync();
    stdout.writeln(const ExcelToJson().toJson(bytes));
  } on FileSystemException catch (e) {
    stderr.writeln('Could not read ${args.single}: ${e.message}');
    exitCode = 66;
  } on ExcelToJsonException catch (e) {
    stderr.writeln(e.message);
    exitCode = 65;
  }
}
