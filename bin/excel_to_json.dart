// The `excel-to-json` command: converts an .xlsx or .csv file to JSON.
import 'dart:convert';
import 'dart:io';

import 'package:excel_to_json/excel_to_json.dart';

const _usage = '''
Converts an .xlsx or .csv spreadsheet to JSON.

Usage: excel-to-json <file> [options]

Options:
  --sheet <name>      Convert only this sheet (repeat for more).
  --header-row <n>    Row with the column names, as Excel numbers it
                      (default 1). "none" uses the column letters as keys.
  --keys <style>      original (default), snake or camel.
  --fill-merged       Repeat merged cell values in every cell they cover.
  --formula-text      Write formulas as text instead of their saved results.
  --empty-rows        Keep rows with no values.
  --skip-hidden       Leave out sheets hidden in Excel.
  --pretty            Indent the JSON.
  -h, --help          Show this help.

Options also take the form --option=value. Exit codes: 64 bad usage,
65 unreadable spreadsheet, 66 file not found, 74 output not written.''';

Future<void> main(List<String> args) async {
  final String json;
  try {
    final options = _Options.parse(args);
    if (options == null) {
      stdout.writeln(_usage);
      return;
    }
    final bytes = File(options.path).readAsBytesSync();
    final map = ExcelToJson(config: options.config).toMap(bytes);
    // toMap with date strings is already plain JSON data.
    final encoder = options.pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    json = encoder.convert(map);
  } on FormatException catch (e) {
    stderr
      ..writeln('excel-to-json: ${e.message}')
      ..writeln('Run excel-to-json --help for the options.');
    exitCode = 64;
    return;
  } on FileSystemException catch (e) {
    stderr.writeln(
      'excel-to-json: could not read ${e.path}: ${e.osError?.message ?? e.message}',
    );
    exitCode = 66;
    return;
  } on ExcelToJsonException catch (e) {
    stderr.writeln(
      'excel-to-json: ${e.message}${e.cause == null ? '' : ' (${e.cause})'}',
    );
    exitCode = 65;
    return;
  }

  // A reader that stops early (`| head`) closes the pipe; that is not an
  // error. Anything else, such as a full disk, is.
  stdout.done.ignore();
  try {
    stdout.writeln(json);
    await stdout.flush();
  } on FileSystemException catch (e) {
    if (e.osError?.errorCode != _brokenPipe) {
      stderr.writeln('excel-to-json: could not write the output: ${e.message}');
      exitCode = 74;
    }
  }
}

/// EPIPE on Linux and macOS.
const _brokenPipe = 32;

class _Options {
  _Options(this.path, this.config, {required this.pretty});

  final String path;
  final ExcelToJsonConfig config;
  final bool pretty;

  /// The options in [args], or null when help was asked for.
  static _Options? parse(List<String> args) {
    String? path;
    final sheets = <String>[];
    int? headerRow = 1;
    var keyStyle = KeyStyle.original;
    var fillMerged = false;
    var formulaResults = true;
    var emptyRows = false;
    var hidden = true;
    var pretty = false;

    // `--flag=value` carries its value; `--flag value` takes the next word.
    String? inline;
    String value(Iterator<String> rest, String flag) {
      if (inline case final given?) return given;
      if (!rest.moveNext() || rest.current.startsWith('-')) {
        throw FormatException('$flag needs a value');
      }
      return rest.current;
    }

    final rest = args.iterator;
    var options = true;
    while (rest.moveNext()) {
      var argument = rest.current;
      inline = null;
      if (options && argument.startsWith('--') && argument.contains('=')) {
        final equals = argument.indexOf('=');
        inline = argument.substring(equals + 1);
        argument = argument.substring(0, equals);
      }
      if (!options) {
        // After `--` every word is the file, even one starting with `-`.
        if (path != null) throw const FormatException('give a single file');
        path = argument;
        continue;
      }
      switch (argument) {
        case '--' when options:
          options = false;
        case '-h' || '--help':
          return null;
        case '--sheet':
          sheets.add(value(rest, '--sheet'));
        case '--header-row':
          final row = value(rest, '--header-row');
          headerRow = row == 'none' ? null : int.tryParse(row);
          if (row != 'none' && (headerRow == null || headerRow < 1)) {
            throw const FormatException(
              '--header-row must be 1 or more, or none',
            );
          }
        case '--keys':
          keyStyle = switch (value(rest, '--keys')) {
            'original' => KeyStyle.original,
            'snake' => KeyStyle.snakeCase,
            'camel' => KeyStyle.camelCase,
            final other => throw FormatException('unknown key style "$other"'),
          };
        case '--fill-merged':
          fillMerged = true;
        case '--formula-text':
          formulaResults = false;
        case '--empty-rows':
          emptyRows = true;
        case '--skip-hidden':
          hidden = false;
        case '--pretty':
          pretty = true;
        case final flag when flag.startsWith('-'):
          throw FormatException('unknown option $flag');
        case final file when path == null:
          path = file;
        default:
          throw const FormatException('give a single file');
      }
    }
    if (path == null) throw const FormatException('give the file to convert');

    return _Options(
      path,
      ExcelToJsonConfig(
        headerRow: headerRow,
        sheets: sheets.isEmpty ? null : sheets,
        keyStyle: keyStyle,
        fillMergedCells: fillMerged,
        formulaResults: formulaResults,
        includeEmptyRows: emptyRows,
        includeHiddenSheets: hidden,
      ),
      pretty: pretty,
    );
  }
}
