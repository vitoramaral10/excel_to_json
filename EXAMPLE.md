# Examples

This file contains practical examples of using the `excel_to_json` package.

## Basic Usage

The simplest way to convert an Excel file to JSON:

```dart
import 'package:excel_to_json/excel_to_json.dart';

void main() async {
  final converter = ExcelToJson();
  
  try {
    final jsonString = await converter.convert();
    if (jsonString != null) {
      print('Conversion successful!');
      print(jsonString);
    }
  } on ExcelToJsonException catch (e) {
    print('Error: ${e.message}');
  }
}
```

## Custom Configuration

Use configuration options for more control:

```dart
import 'package:excel_to_json/excel_to_json.dart';

void advancedExample() async {
  const config = ExcelToJsonConfig(
    includeEmptyRows: true,     // Include empty rows
    useDateTimeStrings: false,  // Keep native date types
    verbose: true,              // Enable logging
  );
  
  final converter = ExcelToJson(config: config);
  final result = await converter.convert();
}
```

## Processing JSON Data

Working with the converted JSON:

```dart
import 'dart:convert';
import 'package:excel_to_json/excel_to_json.dart';

void processData() async {
  final converter = ExcelToJson();
  final jsonString = await converter.convert();
  
  if (jsonString != null) {
    // Parse JSON
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // Access worksheets
    for (final entry in data.entries) {
      final sheetName = entry.key;
      final rows = entry.value as List<dynamic>;
      
      print('Sheet: $sheetName has ${rows.length} rows');
      
      // Process each row
      for (final row in rows) {
        final rowData = row as Map<String, dynamic>;
        print('Row data: $rowData');
      }
    }
  }
}
```

## Error Handling

Comprehensive error handling:

```dart
import 'package:excel_to_json/excel_to_json.dart';

void errorHandlingExample() async {
  final converter = ExcelToJson(
    config: const ExcelToJsonConfig(verbose: true),
  );
  
  try {
    final result = await converter.convert();
    
    if (result != null) {
      print('Success: ${result.length} characters converted');
    } else {
      print('User cancelled file selection');
    }
  } on ExcelToJsonException catch (e) {
    print('Conversion error: ${e.message}');
    if (e.cause != null) {
      print('Root cause: ${e.cause}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}
```

## Flutter Widget Example

Using in a Flutter widget:

```dart
import 'package:flutter/material.dart';
import 'package:excel_to_json/excel_to_json.dart';

class ExcelConverterWidget extends StatefulWidget {
  @override
  _ExcelConverterWidgetState createState() => _ExcelConverterWidgetState();
}

class _ExcelConverterWidgetState extends State<ExcelConverterWidget> {
  String? _result;
  bool _isLoading = false;

  Future<void> _convertFile() async {
    setState(() => _isLoading = true);
    
    try {
      final converter = ExcelToJson();
      final result = await converter.convert();
      
      setState(() {
        _result = result ?? 'No file selected';
        _isLoading = false;
      });
    } on ExcelToJsonException catch (e) {
      setState(() {
        _result = 'Error: ${e.message}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _convertFile,
          child: Text(_isLoading ? 'Converting...' : 'Convert Excel'),
        ),
        if (_result != null)
          Expanded(
            child: SingleChildScrollView(
              child: Text(_result!),
            ),
          ),
      ],
    );
  }
}
```

## Expected JSON Output

Given an Excel file with this data:

**Sheet1:**
| Name | Age | Email |
|------|-----|-------|
| John | 30 | john@email.com |
| Jane | 25 | jane@email.com |

**Sheet2:**
| Product | Price | Available |
|---------|-------|-----------|
| Widget | 19.99 | TRUE |
| Gadget | 29.99 | FALSE |

The output will be:

```json
{
  "Sheet1": [
    {
      "Name": "John",
      "Age": 30,
      "Email": "john@email.com"
    },
    {
      "Name": "Jane",
      "Age": 25,
      "Email": "jane@email.com"
    }
  ],
  "Sheet2": [
    {
      "Product": "Widget",
      "Price": 19.99,
      "Available": true
    },
    {
      "Product": "Gadget",
      "Price": 29.99,
      "Available": false
    }
  ]
}
```
