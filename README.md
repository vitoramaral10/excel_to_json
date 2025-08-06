# Excel to JSON

[![pub package](https://img.shields.io/pub/v/excel_to_json.svg)](https://pub.dev/packages/excel_to_json)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pub points](https://img.shields.io/pub/points/excel_to_json)](https://pub.dev/packages/excel_to_json/score)
[![popularity](https://img.shields.io/pub/popularity/excel_to_json)](https://pub.dev/packages/excel_to_json/score)

A Flutter package that converts Excel (.xlsx) files to JSON format, making it easy to work with spreadsheet data in your Flutter applications.

## 🚀 Quick Example

```dart
import 'package:excel_to_json/excel_to_json.dart';

// Simple conversion
final converter = ExcelToJson();
final jsonString = await converter.convert(); // Opens file picker

// With custom configuration  
final converter = ExcelToJson(
  config: ExcelToJsonConfig(
    includeEmptyRows: true,
    verbose: true,
  ),
);
final result = await converter.convert();
```

## Features

✅ **Simple Integration** - Easy to use API with just a few lines of code  
✅ **Multiple Worksheets** - Supports Excel files with multiple sheets  
✅ **Type Safety** - Handles various cell types (text, numbers, dates, formulas, booleans)  
✅ **Configurable** - Customizable conversion options  
✅ **Error Handling** - Comprehensive error reporting and logging  
✅ **Cross Platform** - Works on Android, iOS, Web, and Desktop  

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  excel_to_json: ^1.5.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:excel_to_json/excel_to_json.dart';

void convertExcelToJson() async {
  final converter = ExcelToJson();
  
  try {
    final jsonString = await converter.convert();
    if (jsonString != null) {
      print('Conversion successful!');
      print(jsonString);
    } else {
      print('No file selected or conversion cancelled.');
    }
  } on ExcelToJsonException catch (e) {
    print('Conversion failed: ${e.message}');
  }
}
```

### Advanced Usage with Configuration

```dart
import 'package:excel_to_json/excel_to_json.dart';

void convertWithConfig() async {
  const config = ExcelToJsonConfig(
    includeEmptyRows: true,        // Include rows with all empty cells
    useDateTimeStrings: false,     // Keep date objects as native types
    verbose: true,                 // Enable detailed logging
  );
  
  final converter = ExcelToJson(config: config);
  
  try {
    final jsonString = await converter.convert();
    if (jsonString != null) {
      // Process your JSON data
      final data = jsonDecode(jsonString);
      
      // Access worksheets by name
      final sheet1Data = data['Sheet1'] as List<dynamic>;
      for (final row in sheet1Data) {
        print('Row data: $row');
      }
    }
  } on ExcelToJsonException catch (e) {
    print('Error: ${e.message}');
    if (e.cause != null) {
      print('Caused by: ${e.cause}');
    }
  }
}
```

## Configuration Options

The `ExcelToJsonConfig` class provides several options to customize the conversion:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `includeEmptyRows` | `bool` | `false` | Include rows where all cells are empty |
| `useDateTimeStrings` | `bool` | `true` | Convert date/time values to strings |
| `dateFormat` | `String?` | `null` | Custom date format pattern (future feature) |
| `verbose` | `bool` | `false` | Enable detailed logging during conversion |

## Output Format

The package converts Excel files to JSON with the following structure:

```json
{
  "Sheet1": [
    {
      "Name": "John Doe",
      "Age": 30,
      "Email": "john@example.com"
    },
    {
      "Name": "Jane Smith",
      "Age": 25,
      "Email": "jane@example.com"
    }
  ],
  "Sheet2": [
    {
      "Product": "Widget",
      "Price": 19.99,
      "InStock": true
    }
  ]
}
```

Each worksheet becomes a top-level property, and each row (except the header) becomes an object in the array.

## Supported Cell Types

The package handles all standard Excel cell types:

- **Text** - String values
- **Numbers** - Integer and floating-point numbers
- **Booleans** - TRUE/FALSE values
- **Dates** - Date values (converted to strings by default)
- **Times** - Time values (converted to strings by default)
- **DateTime** - Combined date and time values
- **Formulas** - Formula expressions (shows the formula, not the result)
- **Empty cells** - Represented as `null` in JSON

## Error Handling

The package provides detailed error information through the `ExcelToJsonException` class:

```dart
try {
  final result = await converter.convert();
} on ExcelToJsonException catch (e) {
  print('Conversion failed: ${e.message}');
  
  // Check if there's an underlying cause
  if (e.cause != null) {
    print('Underlying error: ${e.cause}');
  }
}
```

## Platform Support

This package supports all platforms where Flutter runs:

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

## Example App

Check out the `/example` folder for a complete Flutter app demonstrating how to use this package.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/excel_to_json.git`
3. Install dependencies: `flutter pub get`
4. Run tests: `flutter test`
5. Make your changes and add tests
6. Submit a pull request

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this package helpful, please give it a ⭐ on [GitHub](https://github.com/vitoramaral10/excel_to_json) and [pub.dev](https://pub.dev/packages/excel_to_json)!
