import 'config.dart';

/// The Excel letter of the zero-based column [index]: 0 is `A`, 26 is `AA`.
String columnLetter(int index) {
  final letters = StringBuffer();
  for (var n = index + 1; n > 0; n = (n - 1) ~/ 26) {
    letters.write(String.fromCharCode(65 + (n - 1) % 26));
  }
  return letters.toString().split('').reversed.join();
}

/// [header] written in [style]; empty when nothing usable is left.
String styleKey(String header, KeyStyle style) {
  final text = header.trim().replaceAll(_whitespace, ' ');
  if (style == KeyStyle.original) return text;

  final words = _withoutAccents(text)
      .toLowerCase()
      .split(_nonAlphanumeric)
      .where((word) => word.isNotEmpty)
      .toList();
  if (style == KeyStyle.snakeCase || words.isEmpty) return words.join('_');
  return [
    words.first,
    for (final word in words.skip(1))
      word.substring(0, 1).toUpperCase() + word.substring(1),
  ].join();
}

/// [keys] with repeats made unique: the second `Name` becomes `Name_2`.
List<String> uniqueKeys(List<String> keys) {
  final used = <String>{};
  String unique(String key) {
    var candidate = key;
    for (var n = 2; !used.add(candidate); n++) {
      candidate = '${key}_$n';
    }
    return candidate;
  }

  return [for (final key in keys) unique(key)];
}

final _whitespace = RegExp(r'\s+');
// Letters and digits of any script; only Latin accents are folded.
final _nonAlphanumeric = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

String _withoutAccents(String text) => text.replaceAllMapped(
      _accented,
      (match) => _plain[match[0]]!,
    );

const _plain = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
  'ç': 'c', 'Ç': 'C', 'ñ': 'n', 'Ñ': 'N', 'ý': 'y', 'ÿ': 'y', 'Ý': 'Y',
};

final _accented = RegExp('[${_plain.keys.join()}]');
