/// How [ExcelToJsonConfig.keyStyle] writes the column names.
enum KeyStyle {
  /// The header text with spaces trimmed and runs of whitespace collapsed:
  /// `"  Data de  Nascimento "` becomes `"Data de Nascimento"`.
  original,

  /// Lowercase words joined by `_`, without accents:
  /// `"Data de Nascimento"` becomes `"data_de_nascimento"`.
  snakeCase,

  /// Words joined in camelCase, without accents:
  /// `"Data de Nascimento"` becomes `"dataDeNascimento"`.
  camelCase,
}

/// Options for `ExcelToJson`.
class ExcelToJsonConfig {
  /// Creates the options. The defaults read the first row as the header, use
  /// the value formulas last computed to, skip empty rows and write dates as
  /// ISO 8601 strings.
  const ExcelToJsonConfig({
    this.headerRow = 1,
    this.sheets,
    this.includeHiddenSheets = true,
    this.includeEmptyRows = false,
    this.useDateTimeStrings = true,
    this.formulaResults = true,
    this.fillMergedCells = false,
    this.keyStyle = KeyStyle.original,
  }) : assert(headerRow == null || headerRow > 0, 'headerRow starts at 1');

  /// The row with the column names, numbered as Excel shows them (1 is the
  /// first row). Rows above it, such as a title, are ignored.
  ///
  /// When null there is no header: every row is data and the keys are the
  /// column letters (`A`, `B`, ..., `AA`).
  final int? headerRow;

  /// The sheets to convert, by name; null converts all of them.
  ///
  /// Naming a sheet the file does not have throws `ExcelToJsonException`.
  final List<String>? sheets;

  /// Whether sheets hidden in Excel are converted when [sheets] is null.
  ///
  /// Workbooks often keep lookup tables in hidden sheets. A sheet named in
  /// [sheets] is converted either way.
  final bool includeHiddenSheets;

  /// Whether rows whose cells are all empty are kept, as maps of nulls.
  final bool includeEmptyRows;

  /// Whether `ExcelToJson.toMap` gives dates and times as ISO 8601 strings.
  ///
  /// When false, dates and date-times come as [DateTime] (UTC) and times of
  /// day as [Duration]. `ExcelToJson.toJson` always writes strings, since
  /// JSON has no date type.
  final bool useDateTimeStrings;

  /// Whether a formula cell gives the value it was last computed to, as Excel,
  /// LibreOffice and Google Sheets save it, instead of the formula text.
  ///
  /// Files written by libraries that do not compute formulas have no saved
  /// value; those cells give the formula text either way.
  final bool formulaResults;

  /// Whether a merged cell's value is repeated in every cell the merge covers.
  /// Otherwise only its top-left cell has the value, as in the file.
  final bool fillMergedCells;

  /// How the column names are written as keys.
  final KeyStyle keyStyle;
}
