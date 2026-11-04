# excel_to_json examples

Copy-paste recipes for turning spreadsheets into JSON in Dart and Flutter.
Every snippet needs only:

```dart
import 'package:excel_to_json/excel_to_json.dart';
```

## Convert a file

```dart
import 'dart:io';

final bytes = File('people.xlsx').readAsBytesSync();
print(const ExcelToJson().toJson(bytes));
// {"Sheet1":[{"Name":"Ana","Age":30},{"Name":"Bruno","Age":41}]}
// A people.csv gives the same, with every value as text: "Age":"30".
```

## Read rows into your models

```dart
final rows = const ExcelToJson().toMap(bytes)['Sheet1']!;
final people = [for (final row in rows) Person.fromJson(row)];
```

## A report with a title above the header

```dart
// Row 1: "Sales 2026", row 2: blank, row 3: the column names.
const converter = ExcelToJson(config: ExcelToJsonConfig(headerRow: 3));
```

## Keys for code, from any header

```dart
const converter = ExcelToJson(
  config: ExcelToJsonConfig(keyStyle: KeyStyle.camelCase),
);
// "Data de Nascimento" -> "dataDeNascimento"
```

## Dates as DateTime

```dart
const converter = ExcelToJson(
  config: ExcelToJsonConfig(useDateTimeStrings: false),
);
final birth = converter.toMap(bytes)['Sheet1']!.first['Birth'] as DateTime;
```

## Merged cells filled in

```dart
const converter = ExcelToJson(
  config: ExcelToJsonConfig(fillMergedCells: true),
);
```

## Only one sheet

```dart
const converter = ExcelToJson(config: ExcelToJsonConfig(sheets: ['Sales']));
```

## Without freezing a Flutter screen

A large spreadsheet takes a moment to convert; do it off the UI thread with
`compute` from `package:flutter/foundation.dart`:

```dart
final map = await compute(const ExcelToJson().toMap, bytes);
```

## Handle errors

```dart
try {
  const ExcelToJson().toJson(bytes);
} on ExcelToJsonException catch (e) {
  showError('Could not read the spreadsheet: ${e.message}');
}
```

## From the command line

```bash
dart pub global activate excel_to_json
excel-to-json report.xlsx --header-row 3 --keys snake --pretty > report.json
```

## Run the example

[`excel_to_json_example.dart`](excel_to_json_example.dart) converts the file
you pass it:

```bash
dart run example/excel_to_json_example.dart people.xlsx
```
