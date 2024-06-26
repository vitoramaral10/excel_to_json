# Excel to Json

A package that converts `XLSX` files to `JSON` files.

## Warning

This project only recognizes `XLSX` files and converts them into json files.

## Installation

```bash
    flutter pub add excel_to_json
```

## Usage

```dart
import 'package:excel_to_json/excel_to_json.dart';

void main() {
  final excelToJson = ExcelToJson();

  String? excel = await excelToJson.convert();
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Community

### How to contribute

We welcome contributions to this project. Please read the [Contributing Guidelines](CONTRIBUTING.md) for more information.
