import 'dart:io';

import 'package:excel/excel.dart';

/// Script to generate test Excel files for integration tests
void main() {
  print('Generating test Excel files...');

  // Create fixtures directory if it doesn't exist
  final fixturesDir = Directory('test/fixtures');
  if (!fixturesDir.existsSync()) {
    fixturesDir.createSync(recursive: true);
  }

  // Generate simple Excel file
  _generateSimpleExcel();

  // Generate Excel with multiple sheets
  _generateMultipleSheetsExcel();

  // Generate Excel with different cell types
  _generateCellTypesExcel();

  // Generate Excel with empty rows
  _generateEmptyRowsExcel();

  print('✅ All test Excel files generated successfully!');
}

void _generateSimpleExcel() {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  // Add headers
  sheet.appendRow([
    TextCellValue('Name'),
    TextCellValue('Age'),
    TextCellValue('Email'),
  ]);

  // Add data rows
  sheet.appendRow([
    TextCellValue('John Doe'),
    IntCellValue(30),
    TextCellValue('john@example.com'),
  ]);

  sheet.appendRow([
    TextCellValue('Jane Smith'),
    IntCellValue(25),
    TextCellValue('jane@example.com'),
  ]);

  sheet.appendRow([
    TextCellValue('Bob Johnson'),
    IntCellValue(35),
    TextCellValue('bob@example.com'),
  ]);

  // Save file
  final bytes = excel.encode();
  File('test/fixtures/simple.xlsx').writeAsBytesSync(bytes!);
  print('Created: simple.xlsx');
}

void _generateMultipleSheetsExcel() {
  final excel = Excel.createExcel();

  // First sheet - Products
  final sheet1 = excel['Products'];
  sheet1.appendRow([
    TextCellValue('Product'),
    TextCellValue('Price'),
    TextCellValue('InStock'),
  ]);
  sheet1.appendRow([
    TextCellValue('Widget'),
    DoubleCellValue(19.99),
    BoolCellValue(true),
  ]);
  sheet1.appendRow([
    TextCellValue('Gadget'),
    DoubleCellValue(29.99),
    BoolCellValue(false),
  ]);

  // Second sheet - Customers
  final sheet2 = excel['Customers'];
  sheet2.appendRow([
    TextCellValue('Name'),
    TextCellValue('City'),
    TextCellValue('Country'),
  ]);
  sheet2.appendRow([
    TextCellValue('Alice'),
    TextCellValue('New York'),
    TextCellValue('USA'),
  ]);
  sheet2.appendRow([
    TextCellValue('Bob'),
    TextCellValue('London'),
    TextCellValue('UK'),
  ]);

  // Third sheet - Orders
  final sheet3 = excel['Orders'];
  sheet3.appendRow([
    TextCellValue('OrderID'),
    TextCellValue('Customer'),
    TextCellValue('Total'),
  ]);
  sheet3.appendRow([
    IntCellValue(1001),
    TextCellValue('Alice'),
    DoubleCellValue(59.97),
  ]);

  // Remove default sheet
  excel.delete('Sheet1');

  // Save file
  final bytes = excel.encode();
  File('test/fixtures/multiple_sheets.xlsx').writeAsBytesSync(bytes!);
  print('Created: multiple_sheets.xlsx');
}

void _generateCellTypesExcel() {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  // Add headers
  sheet.appendRow([
    TextCellValue('Type'),
    TextCellValue('Value'),
    TextCellValue('Example'),
  ]);

  // Text
  sheet.appendRow([
    TextCellValue('Text'),
    TextCellValue('String'),
    TextCellValue('Hello World'),
  ]);

  // Integer
  sheet.appendRow([
    TextCellValue('Integer'),
    TextCellValue('Number'),
    IntCellValue(42),
  ]);

  // Double
  sheet.appendRow([
    TextCellValue('Double'),
    TextCellValue('Decimal'),
    DoubleCellValue(3.14159),
  ]);

  // Boolean
  sheet.appendRow([
    TextCellValue('Boolean'),
    TextCellValue('True/False'),
    BoolCellValue(true),
  ]);

  sheet.appendRow([
    TextCellValue('Boolean'),
    TextCellValue('True/False'),
    BoolCellValue(false),
  ]);

  // Date
  sheet.appendRow([
    TextCellValue('Date'),
    TextCellValue('DateTime'),
    DateCellValue(
      year: 2026,
      month: 2,
      day: 8,
    ),
  ]);

  // Time
  sheet.appendRow([
    TextCellValue('Time'),
    TextCellValue('Time'),
    TimeCellValue(
      hour: 14,
      minute: 30,
      second: 0,
    ),
  ]);

  // DateTime
  sheet.appendRow([
    TextCellValue('DateTime'),
    TextCellValue('Full'),
    DateTimeCellValue(
      year: 2026,
      month: 2,
      day: 8,
      hour: 14,
      minute: 30,
      second: 0,
    ),
  ]);

  // Formula (note: Excel package may handle formulas differently)
  sheet.appendRow([
    TextCellValue('Formula'),
    TextCellValue('Calculation'),
    FormulaCellValue('SUM(C2:C4)'),
  ]);

  // Null/Empty
  sheet.appendRow([
    TextCellValue('Null'),
    TextCellValue('Empty'),
    TextCellValue(''),
  ]);

  // Save file
  final bytes = excel.encode();
  File('test/fixtures/cell_types.xlsx').writeAsBytesSync(bytes!);
  print('Created: cell_types.xlsx');
}

void _generateEmptyRowsExcel() {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  // Add headers
  sheet.appendRow([
    TextCellValue('ID'),
    TextCellValue('Name'),
    TextCellValue('Value'),
  ]);

  // Add data row
  sheet.appendRow([
    IntCellValue(1),
    TextCellValue('First'),
    IntCellValue(100),
  ]);

  // Add empty row (all null values)
  sheet.appendRow([
    TextCellValue(''),
    TextCellValue(''),
    TextCellValue(''),
  ]);

  // Add another data row
  sheet.appendRow([
    IntCellValue(2),
    TextCellValue('Second'),
    IntCellValue(200),
  ]);

  // Add another empty row
  sheet.appendRow([
    TextCellValue(''),
    TextCellValue(''),
    TextCellValue(''),
  ]);

  // Add final data row
  sheet.appendRow([
    IntCellValue(3),
    TextCellValue('Third'),
    IntCellValue(300),
  ]);

  // Save file
  final bytes = excel.encode();
  File('test/fixtures/empty_rows.xlsx').writeAsBytesSync(bytes!);
  print('Created: empty_rows.xlsx');
}
