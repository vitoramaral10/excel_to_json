# Migration Guide

## Migrating from v1.4.x to v1.5.0

This guide helps you upgrade from version 1.4.x to 1.5.0 of the `excel_to_json` package.

### What's Changed

Version 1.5.0 introduces several improvements while maintaining backward compatibility for basic usage.

### ✅ No Changes Required (Basic Usage)

If you're using the basic API, your existing code will continue to work:

```dart
// This still works exactly the same
final converter = ExcelToJson();
final result = await converter.convert();
```

### 🔧 Enhanced Error Handling

**Before (v1.4.x):**
```dart
try {
  final result = await converter.convert();
} catch (e) {
  print('Error: $e'); // Generic exception
}
```

**After (v1.5.0):**
```dart
try {
  final result = await converter.convert();
} on ExcelToJsonException catch (e) {
  print('Conversion error: ${e.message}');
  if (e.cause != null) {
    print('Root cause: ${e.cause}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

### 🎛️ New Configuration Options

**Before (v1.4.x):**
```dart
// Limited customization
final converter = ExcelToJson();
```

**After (v1.5.0):**
```dart
// Configurable conversion
final converter = ExcelToJson(
  config: ExcelToJsonConfig(
    includeEmptyRows: true,    // New: Include empty rows
    useDateTimeStrings: false, // New: Control date format
    verbose: true,             // New: Enable logging
  ),
);
```

### 🔍 Breaking Changes

#### Exception Type Change

- **Old**: Generic `Exception` thrown on errors  
- **New**: `ExcelToJsonException` with detailed error information

**Migration:**
```dart
// Update your catch blocks
try {
  await converter.convert();
} on ExcelToJsonException catch (e) { // Changed from 'Exception'
  // Handle conversion-specific errors
}
```

#### Constructor Parameters

- **Old**: `ExcelToJson()` - no parameters
- **New**: `ExcelToJson({ExcelToJsonConfig? config})` - optional config parameter

**Migration:**
```dart
// Old way (still works)
final converter = ExcelToJson();

// New way (optional)  
final converter = ExcelToJson(
  config: ExcelToJsonConfig(verbose: true),
);
```

### 📚 New Features You Can Use

#### 1. Verbose Logging
```dart
final converter = ExcelToJson(
  config: ExcelToJsonConfig(verbose: true),
);
// Now you'll see detailed conversion logs
```

#### 2. Include Empty Rows
```dart
final converter = ExcelToJson(
  config: ExcelToJsonConfig(includeEmptyRows: true),
);
// Empty rows will be included in JSON output
```

#### 3. Better Error Information
```dart
try {
  await converter.convert();
} on ExcelToJsonException catch (e) {
  print('Error: ${e.message}');
  print('Cause: ${e.cause}');
  print('Full exception: $e');
}
```

### 🧪 Testing Changes

If you have tests, you may need to update exception handling:

**Before:**
```dart
expect(() => converter.convert(), throwsException);
```

**After:**
```dart
expect(() => converter.convert(), throwsA(isA<ExcelToJsonException>()));
```

### 📦 Dependencies

- No changes to minimum SDK requirements
- All dependencies updated to latest compatible versions
- Removed unused `path_provider` dependency

### 🚀 Performance Improvements

- Better memory usage for large files
- More efficient cell type conversion
- Improved error reporting without performance penalty

### ❓ Need Help?

- Check the updated [README.md](README.md) for examples
- See [EXAMPLE.md](EXAMPLE.md) for detailed usage patterns
- Review [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API reference
- Open an issue on [GitHub](https://github.com/vitoramaral10/excel_to_json/issues) if you need assistance

### ✨ Recommended Migration Steps

1. **Update pubspec.yaml:**
   ```yaml
   dependencies:
     excel_to_json: ^1.5.0
   ```

2. **Run tests** to ensure compatibility

3. **Update error handling** to use `ExcelToJsonException`

4. **Consider using new configuration options** for enhanced functionality

5. **Update documentation** in your project if needed

The migration is designed to be smooth and non-breaking for most use cases!
