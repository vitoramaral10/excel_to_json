import 'dart:convert';

/// The rows of a CSV file; empty fields are null.
///
/// Reads UTF-8 (with or without a BOM) and falls back to Windows-1252, the
/// encoding of CSVs saved by Excel on Windows in Western languages. The delimiter is the one of
/// `,`, `;` and tab that appears most in the first lines; `;` is what Excel
/// uses where the decimal separator is a comma, as in Brazil.
List<List<String?>> parseCsv(List<int> bytes) {
  final text = _decode(bytes);
  final delimiter = _delimiter(text);

  final rows = <List<String?>>[];
  var row = <String?>[];
  final field = StringBuffer();
  var quoted = false; // inside a quoted field
  var wasQuoted = false; // the current field had quotes, so '' is kept

  void endField() {
    row.add(field.isEmpty && !wasQuoted ? null : field.toString());
    field.clear();
    wasQuoted = false;
  }

  void endRow() {
    endField();
    rows.add(row);
    row = [];
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (quoted) {
      if (char != '"') {
        field.write(char);
      } else if (i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = false;
      }
    } else if (char == '"' && field.isEmpty && !wasQuoted) {
      // Quotes open a field only at its start; elsewhere, as in `24"`, they
      // are part of the text.
      quoted = wasQuoted = true;
    } else if (char == delimiter) {
      endField();
    } else if (char == '\n' || char == '\r') {
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else {
      field.write(char);
    }
  }
  // The last line may not end with a newline.
  if (field.isNotEmpty || wasQuoted || row.isNotEmpty) endRow();
  return rows;
}

String _decode(List<int> bytes) {
  const bom = [0xEF, 0xBB, 0xBF];
  final start = bytes.length >= 3 &&
          bytes[0] == bom[0] &&
          bytes[1] == bom[1] &&
          bytes[2] == bom[2]
      ? 3
      : 0;
  final body = bytes.sublist(start);
  try {
    return utf8.decode(body);
  } on FormatException {
    return String.fromCharCodes(body.map(_fromWindows1252));
  }
}

String _delimiter(String text) {
  // A sample of lines, not just the first: a CSV may start with a title, and
  // decimal commas must not outvote the real delimiter.
  final lines = const LineSplitter()
      .convert(text.length > 65536 ? text.substring(0, 65536) : text)
      .where((line) => line.isNotEmpty)
      .take(20)
      .toList();

  // The delimiter that appears the same number of times on the most lines.
  var best = ',';
  var bestScore = 0;
  for (final candidate in [',', ';', '\t']) {
    final counts = [
      for (final line in lines) _countOutsideQuotes(line, candidate),
    ];
    final frequency = <int, int>{};
    for (final count in counts.where((count) => count > 0)) {
      frequency[count] = (frequency[count] ?? 0) + 1;
    }
    final score = frequency.values.fold(0, (top, n) => n > top ? n : top);
    if (score > bestScore) {
      best = candidate;
      bestScore = score;
    }
  }
  return best;
}

/// How many times [delimiter] appears in [line] outside double quotes.
int _countOutsideQuotes(String line, String delimiter) {
  var count = 0;
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      quoted = !quoted;
    } else if (!quoted && char == delimiter) {
      count++;
    }
  }
  return count;
}

int _fromWindows1252(int byte) =>
    byte >= 0x80 && byte < 0xA0 ? _windows1252[byte - 0x80] : byte;

/// Windows-1252 characters for the bytes 0x80 to 0x9F, where it differs from
/// Latin-1; the five unassigned bytes keep their Latin-1 code.
const _windows1252 = [
  0x20AC, 0x81, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x8D, 0x017D, 0x8F,
  0x90, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
  0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x9D, 0x017E, 0x0178,
];
