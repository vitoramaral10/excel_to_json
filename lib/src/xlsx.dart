import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml_events.dart';

/// Reads the sheets of an .xlsx file as grids of Dart values.
///
/// Only what a conversion needs is read: cell values, the number formats that
/// make a number a date, saved formula results and merged ranges. Every XML
/// part is read as a stream of events, matching elements by local name since
/// some writers prefix them (`<x:sheet>`).
class XlsxReader {
  /// Opens the .xlsx [bytes]; throws when they are not a readable workbook.
  XlsxReader(List<int> bytes) : _archive = ZipDecoder().decodeBytes(bytes) {
    // Parts are found through their relationships, as the format defines,
    // with the usual paths as a fallback.
    final workbookPath =
        _related('', '/officeDocument').firstOrNull ?? 'xl/workbook.xml';
    final workbook = _file(workbookPath) ??
        (throw const FormatException('The file has no workbook part'));
    final workbookRels = _relationships(workbookPath);
    final workbookDir = _directory(workbookPath);

    var date1904 = false;
    for (final element in _starts(workbook)) {
      switch (element.name) {
        case 'sheet':
          final name = element['name']!;
          final target = workbookRels[element['id']]?.target;
          _paths[name] = target == null ? null : _resolve(workbookDir, target);
          if (element['state'] case 'hidden' || 'veryHidden') {
            _hidden.add(name);
          }
        case 'workbookPr':
          date1904 = const {'1', 'true'}.contains(element['date1904']);
      }
    }
    _date1904 = date1904;

    String? part(String type, String fallback) {
      for (final rel in workbookRels.values) {
        if (rel.type.endsWith(type)) return _resolve(workbookDir, rel.target);
      }
      return _archive.findFile(fallback) == null ? null : fallback;
    }

    _readSharedStrings(part('/sharedStrings', 'xl/sharedStrings.xml'));
    _readStyles(part('/styles', 'xl/styles.xml'));
  }

  final Archive _archive;
  final _paths = <String, String?>{};
  final _hidden = <String>{};
  late final bool _date1904;
  final _sharedStrings = <String>[];

  /// The kind of value each cell style gives a number, by style index.
  final _styleKinds = <_Kind>[];

  /// The sheet names, in workbook order.
  Iterable<String> get sheetNames => _paths.keys;

  /// The names of the sheets hidden in Excel.
  Set<String> get hiddenSheets => _hidden;

  /// The cell values of sheet [name], row by row; missing cells are null.
  ///
  /// Values are [String], [int], [double], [bool], and for date-formatted
  /// numbers ISO 8601 strings (`HH:mm:ss` for times), or [DateTime] and
  /// [Duration] when [dateStrings] is false.
  ///
  /// Throws [FormatException] when the sheet's part is missing or malformed.
  List<List<Object?>> sheet(
    String name, {
    required bool formulaResults,
    required bool fillMergedCells,
    required bool dateStrings,
  }) {
    final path = _paths[name];
    final text = path == null ? null : _file(path);
    if (text == null) {
      throw FormatException('The part of sheet "$name" is missing');
    }

    final rows = <List<Object?>>[];
    final merges = <String>[];
    var cells = <Object?>[];
    var nextRow = 0;
    var nextColumn = 0;

    // The cell being read.
    String? reference;
    String? type;
    String? style;
    final formula = StringBuffer();
    final saved = StringBuffer();
    final inline = StringBuffer();
    var hasFormula = false;
    var hasSaved = false;
    StringBuffer? target;
    var inInline = false;
    var phonetic = 0;

    void endCell() {
      final column = _position(reference)?.$2 ?? nextColumn;
      nextColumn = column + 1;
      while (cells.length <= column) {
        cells.add(null);
      }
      cells[column] = _value(
        type: type,
        style: style,
        formula: hasFormula ? formula.toString() : null,
        saved: hasSaved ? saved.toString() : null,
        inline: inline.toString(),
        formulaResults: formulaResults,
        dateStrings: dateStrings,
      );
    }

    for (final event in parseEvents(text)) {
      switch (event) {
        case XmlStartElementEvent(
            :final localName,
            :final attributes,
            :final isSelfClosing,
          ):
          switch (localName) {
            case 'row':
              final rowIndex = switch (_attribute(attributes, 'r')) {
                final r? => int.parse(r) - 1,
                null => nextRow,
              };
              nextRow = rowIndex + 1;
              nextColumn = 0;
              while (rows.length <= rowIndex) {
                rows.add([]);
              }
              cells = rows[rowIndex];
            case 'c':
              reference = _attribute(attributes, 'r');
              type = _attribute(attributes, 't');
              style = _attribute(attributes, 's');
              formula.clear();
              saved.clear();
              inline.clear();
              hasFormula = hasSaved = false;
              if (isSelfClosing) endCell();
            case 'f':
              hasFormula = true;
              target = isSelfClosing ? null : formula;
            case 'v':
              hasSaved = true;
              target = isSelfClosing ? null : saved;
            case 'is':
              inInline = !isSelfClosing;
            case 'rPh' when !isSelfClosing:
              phonetic++;
            case 't' when inInline && phonetic == 0 && !isSelfClosing:
              target = inline;
            case 'mergeCell':
              if (_attribute(attributes, 'ref') case final ref?) {
                merges.add(ref);
              }
          }
        case XmlEndElementEvent(:final localName):
          switch (localName) {
            case 'f' || 'v' || 't':
              target = null;
            case 'is':
              inInline = false;
            case 'rPh':
              phonetic--;
            case 'c':
              endCell();
          }
        case XmlTextEvent(:final value) || XmlCDATAEvent(:final value):
          target?.write(value);
        default:
      }
    }

    if (fillMergedCells) _fillMerges(rows, merges);
    return rows;
  }

  /// Copies each merge's top-left value into the cells it covers that are
  /// empty, as a merged cell looks on screen.
  static void _fillMerges(List<List<Object?>> rows, List<String> merges) {
    for (final merge in merges) {
      final corners = merge.split(':');
      final start = _position(corners.first);
      final end = _position(corners.last);
      if (start == null || end == null) continue;
      final (top, bottom) = _ordered(start.$1, end.$1);
      final (left, right) = _ordered(start.$2, end.$2);
      final value =
          top < rows.length && left < rows[top].length ? rows[top][left] : null;
      if (value == null) continue;
      for (var r = top; r <= bottom; r++) {
        while (rows.length <= r) {
          rows.add([]);
        }
        for (var c = left; c <= right; c++) {
          while (rows[r].length <= c) {
            rows[r].add(null);
          }
          rows[r][c] ??= value;
        }
      }
    }
  }

  Object? _value({
    required String? type,
    required String? style,
    required String? formula,
    required String? saved,
    required String inline,
    required bool formulaResults,
    required bool dateStrings,
  }) {
    if (formula != null) {
      // A filled-down (shared) formula has no text of its own, so its saved
      // value is the best answer there is even with formulaResults off.
      if (!formulaResults && formula.isNotEmpty) return formula;
      // No saved value: the file was written without computing it. An empty
      // <v> means the same, except for a text result, where it is ''.
      if (saved == null || (saved.isEmpty && type != 'str')) {
        return formula.isEmpty ? null : formula;
      }
    }

    // Text keeps its spaces; numbers, indexes and flags may be padded.
    final text = saved ?? '';
    final token = text.trim();
    switch (type) {
      case 's':
        return token.isEmpty ? null : _sharedStrings[int.parse(token)];
      case 'inlineStr':
        return _unescape(inline);
      case 'str':
        return _unescape(text);
      case 'e':
        return text;
      case 'b':
        return token.isEmpty
            ? null
            : token == '1' || token.toLowerCase() == 'true';
      case 'd':
        return token.isEmpty ? null : _isoValue(token, dateStrings);
    }
    if (token.isEmpty) return null;

    final number = num.parse(token);
    final index = int.tryParse(style ?? '') ?? 0;
    final kind = index >= 0 && index < _styleKinds.length
        ? _styleKinds[index]
        : _Kind.number;
    return switch (kind) {
      _Kind.number =>
        number is double && number == number.truncate() && number.abs() < 1e15
            ? number.toInt()
            : number,
      _Kind.date => _date(_serialToDate(number), dateStrings),
      _Kind.time => _time(_milliseconds(number), dateStrings, timeOfDay: true),
      _Kind.duration => _time(_milliseconds(number), dateStrings),
    };
  }

  /// A `t="d"` cell: an ISO 8601 date, date-time or time of day.
  Object _isoValue(String iso, bool dateStrings) {
    if (_isoTime.firstMatch(iso) case final match?) {
      final duration = Duration(
        hours: int.parse(match[1]!),
        minutes: int.parse(match[2]!),
        microseconds: ((double.tryParse(match[3] ?? '') ?? 0) * 1e6).round(),
      );
      return _time(duration.inMilliseconds, dateStrings, timeOfDay: true);
    }
    final parsed = DateTime.parse(iso);
    // Without an offset the value is a wall-clock time, read as UTC like
    // serial dates are.
    final date = parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
    return _date(date, dateStrings);
  }

  Object _date(DateTime date, bool dateStrings) =>
      dateStrings ? date.toIso8601String() : date;

  /// [milliseconds] as a [Duration], or as `HH:mm:ss` text; a [timeOfDay]
  /// wraps at midnight.
  Object _time(int milliseconds, bool dateStrings, {bool timeOfDay = false}) {
    final duration = Duration(
      milliseconds: timeOfDay ? milliseconds % 86400000 : milliseconds,
    );
    return dateStrings ? formatDuration(duration) : duration;
  }

  static int _milliseconds(num days) => (days * 86400000).round();

  /// The UTC date of an Excel serial number.
  DateTime _serialToDate(num serial) {
    // 1900 system: day 1 is 1900-01-01, and Excel counts a 1900-02-29 that
    // never existed as day 60, so from there on the base moves back a day.
    // Day 60 itself becomes 1900-02-28, the closest real date.
    final base = _date1904
        ? DateTime.utc(1904)
        : serial < 60
            ? DateTime.utc(1899, 12, 31)
            : DateTime.utc(1899, 12, 30);
    return base.add(Duration(milliseconds: _milliseconds(serial)));
  }

  void _readSharedStrings(String? path) {
    final text = path == null ? null : _file(path);
    if (text == null) return;
    // Every <si> keeps its position, repeats included: cells point at them by
    // index.
    final item = StringBuffer();
    var inText = false;
    var phonetic = 0;
    for (final event in parseEvents(text)) {
      switch (event) {
        case XmlStartElementEvent(:final localName, :final isSelfClosing):
          switch (localName) {
            case 'si':
              item.clear();
              if (isSelfClosing) _sharedStrings.add('');
            case 'rPh' when !isSelfClosing:
              phonetic++;
            case 't' when phonetic == 0 && !isSelfClosing:
              inText = true;
          }
        case XmlEndElementEvent(:final localName):
          switch (localName) {
            case 'si':
              _sharedStrings.add(_unescape(item.toString()));
            case 'rPh':
              phonetic--;
            case 't':
              inText = false;
          }
        case XmlTextEvent(:final value) || XmlCDATAEvent(:final value)
            when inText:
          item.write(value);
        default:
      }
    }
  }

  void _readStyles(String? path) {
    final text = path == null ? null : _file(path);
    if (text == null) return;
    final custom = <int, String>{};
    final formats = <int>[];
    // Formats are declared in <numFmts>; the ones inside <dxfs> belong to
    // conditional formatting. Cells point at the <xf> inside <cellXfs>; the
    // ones in <cellStyleXfs> are named-style bases.
    String? section;
    for (final event in parseEvents(text)) {
      switch (event) {
        case XmlStartElementEvent(
            :final localName,
            :final attributes,
            :final isSelfClosing,
          ):
          switch (localName) {
            case 'numFmts' || 'cellXfs' when !isSelfClosing:
              section = localName;
            case 'numFmt' when section == 'numFmts':
              if (int.tryParse(_attribute(attributes, 'numFmtId') ?? '')
                  case final id?) {
                custom[id] = _attribute(attributes, 'formatCode') ?? '';
              }
            case 'xf' when section == 'cellXfs':
              formats.add(
                int.tryParse(_attribute(attributes, 'numFmtId') ?? '') ?? 0,
              );
          }
        case XmlEndElementEvent(localName: 'numFmts' || 'cellXfs'):
          section = null;
        default:
      }
    }
    _styleKinds.addAll([
      for (final id in formats)
        switch (custom[id]) {
          final code? => _kindOf(code),
          null => _builtInKinds[id] ?? _Kind.number,
        },
    ]);
  }

  /// The relationships of the part at [path], by id.
  Map<String, ({String type, String target})> _relationships(String path) {
    final directory = _directory(path);
    final name = path.substring(directory.length);
    final text = _file('${directory}_rels/$name.rels');
    if (text == null) return {};
    return {
      for (final rel in _starts(text))
        if (rel.name == 'Relationship' && rel['Id'] != null)
          rel['Id']!: (type: rel['Type'] ?? '', target: rel['Target'] ?? ''),
    };
  }

  /// The parts the package root relates with a type ending in [type].
  Iterable<String> _related(String root, String type) => [
        for (final rel in _relationships(root).values)
          if (rel.type.endsWith(type)) _resolve('', rel.target),
      ];

  String? _file(String path) => switch (_archive.findFile(path)) {
        final file? => utf8.decode(file.content as List<int>),
        null => null,
      };
}

/// `xl/` for `xl/workbook.xml`; empty for a part at the root.
String _directory(String path) => path.substring(0, path.lastIndexOf('/') + 1);

/// [target] resolved against [directory]: relative ones such as
/// `worksheets/sheet1.xml` or `../xl/worksheets/sheet1.xml` from there,
/// absolute ones such as `/xl/worksheets/sheet1.xml` from the root.
String _resolve(String directory, String target) {
  final path = target.replaceAll(r'\', '/');
  final parts = path.startsWith('/')
      ? <String>[]
      : directory.split('/').where((part) => part.isNotEmpty).toList();
  for (final part in path.split('/')) {
    switch (part) {
      case '' || '.':
        break;
      case '..':
        if (parts.isNotEmpty) parts.removeLast();
      default:
        parts.add(part);
    }
  }
  return parts.join('/');
}

/// [duration] as `HH:mm:ss`, with a leading `-` when negative; hours can pass
/// 24.
String formatDuration(Duration duration) {
  final sign = duration.isNegative ? '-' : '';
  final positive = duration.abs();
  String two(int n) => '$n'.padLeft(2, '0');
  return '$sign${two(positive.inHours)}:${two(positive.inMinutes % 60)}:'
      '${two(positive.inSeconds % 60)}';
}

final _escape = RegExp('_x([0-9A-Fa-f]{4})_');

/// Text with Excel's `_xHHHH_` escapes (such as `_x000D_` for a carriage
/// return) decoded.
String _unescape(String text) => text.contains('_x')
    ? text.replaceAllMapped(
        _escape,
        (match) => String.fromCharCode(int.parse(match[1]!, radix: 16)),
      )
    : text;

final _isoTime = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}(?:\.\d+)?))?$');

/// What a number format makes of a cell's number.
enum _Kind {
  number,

  /// A date, with or without a time of day.
  date,

  /// A time of day.
  time,

  /// Elapsed time, such as `[h]:mm`, which can pass 24 hours.
  duration,
}

/// Excel's built-in date and time formats, including the East Asian ones
/// (27 to 36 and 50 to 58); every other built-in id is a number.
const _builtInKinds = {
  14: _Kind.date, 15: _Kind.date, 16: _Kind.date, 17: _Kind.date, //
  18: _Kind.time, 19: _Kind.time, 20: _Kind.time, 21: _Kind.time,
  22: _Kind.date, 45: _Kind.time, 46: _Kind.duration, 47: _Kind.time,
  27: _Kind.date, 28: _Kind.date, 29: _Kind.date, 30: _Kind.date,
  31: _Kind.date, 32: _Kind.time, 33: _Kind.time, 34: _Kind.date,
  35: _Kind.date, 36: _Kind.date, 50: _Kind.date, 51: _Kind.date,
  52: _Kind.date, 53: _Kind.date, 54: _Kind.date, 55: _Kind.time,
  56: _Kind.time, 57: _Kind.date, 58: _Kind.date,
};

final _literal = RegExp(r'"[^"]*"|\\.');
final _bracketed = RegExp(r'\[[^\]]*\]');
final _elapsed = RegExp(r'\[[hms]+\]');

/// Whether a custom format [code] shows a number as a date, a time or both.
_Kind _kindOf(String code) {
  // Only the first section (positive numbers) matters; literal text, colors
  // and locales are not date parts.
  final section = code.split(';').first.replaceAll(_literal, '').toLowerCase();
  if (section.contains(_elapsed)) return _Kind.duration;
  final format = section.replaceAll(_bracketed, '');
  final hasTime = format.contains(RegExp('[hs]'));
  // A lone `m` is a month in a date and minutes next to hours or seconds.
  final hasDate =
      format.contains(RegExp('[dy]')) || (format.contains('m') && !hasTime);
  return hasDate
      ? _Kind.date
      : hasTime
          ? _Kind.time
          : _Kind.number;
}

String? _attribute(List<XmlEventAttribute> attributes, String name) {
  for (final attribute in attributes) {
    if (attribute.localName == name) return attribute.value;
  }
  return null;
}

/// A start tag, with its name and attribute names without prefixes.
class _Tag {
  _Tag(XmlStartElementEvent event)
      : name = event.localName,
        _attributes = event.attributes;

  final String name;
  final List<XmlEventAttribute> _attributes;

  String? operator [](String attribute) => _attribute(_attributes, attribute);
}

/// The start tags of [xml], in order.
Iterable<_Tag> _starts(String xml) =>
    parseEvents(xml).whereType<XmlStartElementEvent>().map(_Tag.new);

(int, int) _ordered(int a, int b) => a <= b ? (a, b) : (b, a);

final _reference = RegExp(r'^\$?([A-Z]+)\$?(\d+)$');

/// `B5` as zero-based (row 4, column 1).
(int, int)? _position(String? reference) {
  final match = _reference.firstMatch(reference ?? '');
  if (match == null) return null;
  var column = 0;
  for (final unit in match[1]!.codeUnits) {
    column = column * 26 + unit - 64;
  }
  return (int.parse(match[2]!) - 1, column - 1);
}
