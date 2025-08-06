# API Documentation

This document provides detailed information about the public API of the `excel_to_json` package.

## Classes

### ExcelToJson

The main class for converting Excel files to JSON format.

#### Constructor

```dart
const ExcelToJson({ExcelToJsonConfig config = const ExcelToJsonConfig()})
```

Creates a new instance of ExcelToJson with optional configuration.

**Parameters:**
- `config` (ExcelToJsonConfig, optional): Configuration options for the conversion process. Defaults to `ExcelToJsonConfig()`.

#### Methods

##### convert()

```dart
Future<String?> convert()
```

Converts an Excel file to JSON format by opening a file picker dialog.

**Returns:**
- `Future<String?>`: A JSON string representation of the Excel data, or `null` if no file was selected.

**Throws:**
- `ExcelToJsonException`: If the conversion fails due to file reading errors, invalid Excel format, or other conversion issues.

**Example:**
```dart
final converter = ExcelToJson();
try {
  final jsonString = await converter.convert();
  if (jsonString != null) {
    print('Conversion successful: $jsonString');
  }
} on ExcelToJsonException catch (e) {
  print('Error: ${e.message}');
}
```

---

### ExcelToJsonConfig

Configuration class that defines options for the Excel to JSON conversion process.

#### Constructor

```dart
const ExcelToJsonConfig({
  bool includeEmptyRows = false,
  bool useDateTimeStrings = true,
  String? dateFormat,
  bool verbose = false,
})
```

Creates a new configuration instance with the specified options.

**Parameters:**
- `includeEmptyRows` (bool, optional): Whether to include rows where all cells are empty. Defaults to `false`.
- `useDateTimeStrings` (bool, optional): Whether to convert date/time values to ISO strings. Defaults to `true`.
- `dateFormat` (String?, optional): Custom date format pattern. Currently reserved for future use. Defaults to `null`.
- `verbose` (bool, optional): Whether to enable detailed logging during conversion. Defaults to `false`.

#### Properties

##### includeEmptyRows

```dart
final bool includeEmptyRows
```

Whether to include rows where all cells are empty in the JSON output.

**Default:** `false`

##### useDateTimeStrings

```dart
final bool useDateTimeStrings
```

Whether to convert date/time values to strings or keep them as native types.

**Default:** `true`

##### dateFormat

```dart
final String? dateFormat
```

Custom date format pattern for date/time conversion. Currently reserved for future use.

**Default:** `null`

##### verbose

```dart
final bool verbose
```

Whether to enable detailed logging during the conversion process.

**Default:** `false`

**Example:**
```dart
const config = ExcelToJsonConfig(
  includeEmptyRows: true,
  useDateTimeStrings: false,
  verbose: true,
);
```

---

### ExcelToJsonException

Custom exception class for Excel to JSON conversion errors.

#### Constructor

```dart
const ExcelToJsonException(String message, [Object? cause])
```

Creates a new exception with the specified message and optional underlying cause.

**Parameters:**
- `message` (String): The error message describing what went wrong.
- `cause` (Object?, optional): The underlying exception that caused this error.

#### Properties

##### message

```dart
final String message
```

The error message describing what went wrong during conversion.

##### cause

```dart
final Object? cause
```

The underlying exception that caused this error, if any.

#### Methods

##### toString()

```dart
String toString()
```

Returns a string representation of the exception including the message and cause.

**Example:**
```dart
try {
  await converter.convert();
} on ExcelToJsonException catch (e) {
  print('Error: ${e.message}');
  if (e.cause != null) {
    print('Caused by: ${e.cause}');
  }
}
```

---

## Data Types

The package handles various Excel cell types and converts them to appropriate JSON types:

| Excel Type | Dart Type | JSON Type | Description |
|------------|-----------|-----------|-------------|
| Text | String | string | Text content from cells |
| Number (Integer) | int | number | Whole numbers |
| Number (Decimal) | double | number | Floating-point numbers |
| Boolean | bool | boolean | TRUE/FALSE values |
| Date | String/DateTime | string | Date values (format depends on config) |
| Time | String/DateTime | string | Time values (format depends on config) |
| DateTime | String/DateTime | string | Combined date and time |
| Formula | String | string | Formula expressions (not results) |
| Empty | null | null | Empty or blank cells |

## Error Handling

The package provides comprehensive error handling through the `ExcelToJsonException` class:

### Common Error Scenarios

1. **File Selection Cancelled**: Returns `null` instead of throwing an exception
2. **File Reading Error**: Throws `ExcelToJsonException` with file-related error details
3. **Invalid Excel Format**: Throws `ExcelToJsonException` with format validation errors
4. **Memory/Processing Errors**: Throws `ExcelToJsonException` with processing error details

### Best Practices

```dart
// Recommended error handling pattern
try {
  final result = await converter.convert();
  if (result != null) {
    // Process successful conversion
    final data = jsonDecode(result);
    // ... work with data
  } else {
    // Handle user cancellation
    print('User cancelled file selection');
  }
} on ExcelToJsonException catch (e) {
  // Handle conversion-specific errors
  print('Conversion error: ${e.message}');
  
  // Log additional details for debugging
  if (e.cause != null) {
    print('Root cause: ${e.cause}');
  }
} on FormatException catch (e) {
  // Handle JSON parsing errors (rare)
  print('JSON parsing error: ${e.message}');
} catch (e) {
  // Handle unexpected errors
  print('Unexpected error: $e');
}
```

## JSON Output Format

The converted JSON follows this structure:

```json
{
  "WorksheetName1": [
    {
      "Column1": "value1",
      "Column2": "value2",
      "Column3": null
    },
    {
      "Column1": "value3",
      "Column2": "value4", 
      "Column3": "value5"
    }
  ],
  "WorksheetName2": [
    ...
  ]
}
```

### Key Points

- Each worksheet becomes a top-level JSON property
- The first row of each worksheet is treated as column headers
- Each subsequent row becomes an object in the worksheet array
- Column headers become JSON object keys
- Empty cells are represented as `null`
- Multiple worksheets are supported in a single conversion

## Platform Support

The package supports all Flutter platforms:

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## Limitations

- Only supports `.xlsx` files (Excel 2007+ format)
- Does not support `.xls` files (Excel 97-2003 format)
- Formula results are not calculated (shows formula text instead)
- Charts, images, and other embedded objects are ignored
- Large files may cause memory issues on low-end devices
