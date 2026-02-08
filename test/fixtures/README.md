# Test Fixtures

This directory contains Excel files used for integration testing.

## Files

- **simple.xlsx** - Basic Excel file with one worksheet containing Name, Age, and Email columns
- **multiple_sheets.xlsx** - Excel file with three worksheets (Products, Customers, Orders)
- **cell_types.xlsx** - Excel file demonstrating all supported cell types (text, numbers, dates, formulas, booleans)
- **empty_rows.xlsx** - Excel file with empty rows mixed with data rows

## Generating Fixtures

To regenerate the test fixtures, run:

```bash
dart test/generate_fixtures.dart
```

This will create all the Excel files in this directory programmatically.
