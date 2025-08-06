# Excel to JSON Example App

This example demonstrates how to use the `excel_to_json` package in a Flutter application.

## Features Demonstrated

- ✅ **Basic Excel to JSON conversion**
- ✅ **Configuration options** (Include empty rows, verbose logging)
- ✅ **Error handling** with user-friendly messages
- ✅ **JSON result display** with syntax highlighting
- ✅ **Copy to clipboard** functionality
- ✅ **Modern Material Design 3** UI

## How to Run

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## How to Use

1. **Configure Options**: Toggle the configuration switches as needed:
   - **Include Empty Rows**: Whether to include rows with all empty cells in the JSON output
   - **Verbose Logging**: Enable detailed logging during conversion (check console/debug output)

2. **Select Excel File**: Click the "Select Excel File & Convert" button to open a file picker

3. **Choose File**: Select an `.xlsx` file from your device

4. **View Results**: The converted JSON will appear in the result area below

5. **Copy Results**: Use the copy button to copy the JSON to your clipboard

6. **Clear Results**: Use the clear button to remove the current result

## Test Excel Files

To test the application, you can create a simple Excel file with:

### Sheet 1 Example:
| Name | Age | Email |
|------|-----|-------|
| John Doe | 30 | john@example.com |
| Jane Smith | 25 | jane@example.com |

### Sheet 2 Example:
| Product | Price | In Stock |
|---------|-------|----------|
| Widget | 19.99 | TRUE |
| Gadget | 29.99 | FALSE |

This will produce JSON output like:
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
      "In Stock": true
    },
    {
      "Product": "Gadget",
      "Price": 29.99, 
      "In Stock": false
    }
  ]
}
```

## Code Structure

- `main.dart` - App entry point and MaterialApp setup
- `home.dart` - Main UI with conversion logic and configuration options
- `test/widget_test.dart` - Widget tests for the UI components

## Error Handling

The app demonstrates proper error handling for common scenarios:

- **No file selected**: User-friendly message when file picker is cancelled
- **File read errors**: Clear error messages for file access issues
- **Conversion errors**: Detailed error information from the package
- **Invalid file format**: Appropriate feedback for non-Excel files

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
