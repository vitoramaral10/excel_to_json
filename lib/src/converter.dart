import 'dart:convert';

import 'config.dart';
import 'csv.dart';
import 'exception.dart';
import 'keys.dart';
import 'xlsx.dart';

/// Converts spreadsheets (.xlsx or .csv) to JSON.
///
/// Each sheet becomes a list of rows, and each row a map from column name to
/// cell value. By default the first row holds the column names; see
/// [ExcelToJsonConfig] for files laid out differently.
class ExcelToJson {
  /// Creates a converter with the given [config].
  const ExcelToJson({this.config = const ExcelToJsonConfig()});

  /// The conversion options.
  final ExcelToJsonConfig config;

  /// Converts the file [bytes] to a map from sheet name to its rows.
  ///
  /// The format is detected from the content: .xlsx (Excel 2007 and later,
  /// also saved by Google Sheets and LibreOffice) or CSV, which comes as one
  /// sheet named `Sheet1` with text values.
  ///
  /// .xlsx cells come as [String], [int], [double], [bool] or null; dates and
  /// times follow [ExcelToJsonConfig.useDateTimeStrings].
  ///
  /// Throws [ExcelToJsonException] when the file cannot be read, is a legacy
  /// .xls, or lacks a sheet named in [ExcelToJsonConfig.sheets].
  Map<String, List<Map<String, Object?>>> toMap(List<int> bytes) =>
      _convert(bytes, dateStrings: config.useDateTimeStrings);

  /// Converts the file [bytes] to a JSON string shaped like [toMap].
  ///
  /// Throws [ExcelToJsonException] in the same cases as [toMap].
  String toJson(List<int> bytes) =>
      jsonEncode(_convert(bytes, dateStrings: true));

  Map<String, List<Map<String, Object?>>> _convert(
    List<int> bytes, {
    required bool dateStrings,
  }) {
    if (config.headerRow case final row? when row < 1) {
      throw ArgumentError.value(row, 'headerRow', 'starts at 1');
    }

    final grids = switch (bytes) {
      [] => throw const ExcelToJsonException('The file is empty'),
      [0x50, 0x4B, 0x03, 0x04, ...] => _xlsx(bytes, dateStrings),
      [0xD0, 0xCF, 0x11, 0xE0, ...] => throw const ExcelToJsonException(
          'Legacy .xls files are not supported; save the file as .xlsx',
        ),
      _ => {
          for (final name in _selected(['Sheet1'])) name: parseCsv(bytes),
        },
    };
    return {
      for (final MapEntry(key: name, value: grid) in grids.entries)
        name: _records(grid),
    };
  }

  Map<String, List<List<Object?>>> _xlsx(List<int> bytes, bool dateStrings) {
    final XlsxReader reader;
    try {
      reader = XlsxReader(bytes);
    } catch (e) {
      throw ExcelToJsonException(
        'Could not read the bytes as an .xlsx file',
        e,
      );
    }

    return {
      for (final name in _selected(reader.sheetNames, reader.hiddenSheets))
        name: _sheet(reader, name, dateStrings),
    };
  }

  List<List<Object?>> _sheet(XlsxReader reader, String name, bool dateStrings) {
    try {
      return reader.sheet(
        name,
        formulaResults: config.formulaResults,
        fillMergedCells: config.fillMergedCells,
        dateStrings: dateStrings,
      );
    } catch (e) {
      throw ExcelToJsonException('Could not read sheet "$name"', e);
    }
  }

  /// The names in [available] that [ExcelToJsonConfig.sheets] asks for.
  List<String> _selected(
    Iterable<String> available, [
    Set<String> hidden = const {},
  ]) {
    final wanted = config.sheets;
    if (wanted == null) {
      return [
        for (final name in available)
          if (config.includeHiddenSheets || !hidden.contains(name)) name,
      ];
    }
    final missing = wanted.where((name) => !available.contains(name));
    if (missing.isNotEmpty) {
      throw ExcelToJsonException(
        'Sheet "${missing.first}" not found; the file has: '
        '${available.join(', ')}',
      );
    }
    return wanted.toSet().toList();
  }

  /// [grid] as maps keyed by the header row, or by column letter.
  List<Map<String, Object?>> _records(List<List<Object?>> grid) {
    final headerIndex = switch (config.headerRow) {
      final row? => row - 1,
      null => null,
    };
    final dataStart = (headerIndex ?? -1) + 1;
    if (dataStart >= grid.length) return [];

    final header = headerIndex == null ? const <Object?>[] : grid[headerIndex];
    final data = grid.sublist(dataStart);
    final width = [header, ...data].fold(
      0,
      (widest, row) => row.length > widest ? row.length : widest,
    );

    // A column with no name in the header keeps its data under its letter;
    // without data it is left out.
    final named = <int, String>{};
    final unnamed = <int, String>{};
    for (var column = 0; column < width; column++) {
      final title = column < header.length ? header[column] : null;
      final name = title == null ? '' : styleKey(_text(title), config.keyStyle);
      if (name.isNotEmpty) {
        named[column] = name;
      } else if (data
          .any((row) => column < row.length && row[column] != null)) {
        unnamed[column] = columnLetter(column);
      }
    }
    // Real names claim their keys before the letter fallbacks do.
    final unique = uniqueKeys([...named.values, ...unnamed.values]);
    final keyOf = {
      for (final (i, column) in [...named.keys, ...unnamed.keys].indexed)
        column: unique[i],
    };
    final columns = keyOf.keys.toList()..sort();
    final keys = [for (final column in columns) keyOf[column]!];

    return [
      for (final row in data)
        if ({
          for (final (i, column) in columns.indexed)
            keys[i]: column < row.length ? row[column] : null,
        }
            case final record
            when config.includeEmptyRows ||
                record.values.any((value) => value != null))
          record,
    ];
  }

  /// A header cell as text; dates and times read the same whatever
  /// [ExcelToJsonConfig.useDateTimeStrings] says.
  static String _text(Object value) => switch (value) {
        DateTime() => value.toIso8601String(),
        Duration() => formatDuration(value),
        _ => '$value',
      };
}
