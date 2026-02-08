# Changelog

## [v2.0.0] - February 8, 2026

### 🎉 Major New Features

#### ✨ Progress Tracking
- **NEW**: Added `ProgressCallback` typedef for monitoring conversion progress
- Callbacks invoked at key points: starting worksheets, periodically during row processing, and upon completion
- Integrate with UI progress indicators for better user experience

#### 🎯 Worksheet Selection
- **NEW**: Added `selectedWorksheets` configuration option
- Convert only specific worksheets instead of all worksheets
- More control over conversion process and improved performance when dealing with large Excel files

#### 📅 Custom Date Formatting
- **IMPLEMENTED**: Custom date format patterns using the `intl` package
- Supports all DateFormat patterns (e.g., 'yyyy-MM-dd', 'dd/MM/yyyy HH:mm:ss', 'MMM d, y')
- Graceful fallback to default formatting if custom pattern fails

### 🔧 Improvements

#### Code Quality
- Expanded test suite from 6 to 15+ unit tests
- Added integration tests with real Excel file fixtures
- Created script to generate test Excel files programmatically
- Improved code coverage significantly

#### CI/CD
- **NEW**: GitHub Actions workflow for automated testing
- **NEW**: Static code analysis workflow
- **NEW**: Coverage reporting with Codecov integration
- **NEW**: Automated publishing workflow for pub.dev

#### Example App
- **NEW**: Dark mode support with manual toggle
- Improved UI/UX with Material Design 3
- Better visual feedback during conversion
- Configuration options now exposed in UI

#### Dependencies
- Updated `excel` from 4.0.3 to 4.0.6
- Updated `file_picker` from 10.2.1 to 10.3.10
- Updated SDK requirement from 3.1.0 to 3.5.0
- Added `intl` ^0.19.0 for date formatting

### 📝 Breaking Changes

> [!WARNING]
> This is a major version update with potential breaking changes

- **API Addition**: `ExcelToJsonConfig` now includes new optional parameters:
  - `onProgress` (ProgressCallback?)
  - `selectedWorksheets` (List<String>?)
- **Date Handling**: Date/time cell values are now converted to DateTime objects before formatting, which may affect custom serialization
- Existing code will continue to work without modifications, but you may want to take advantage of new features

### 🔄 Migration Guide

```dart
// v1.x code (still works in v2.0)
final converter = ExcelToJson();
final result = await converter.convert();

// v2.0 with new features
final converter = ExcelToJson(
  config: ExcelToJsonConfig(
    // Custom date format
    dateFormat: 'dd/MM/yyyy',
    
    // Only convert specific sheets
    selectedWorksheets: ['Sheet1', 'Products'],
    
    // Track progress
    onProgress: (current, total, message) {
      print('Progress: $current/$total - $message');
    },
    
    // Other existing options
    includeEmptyRows: true,
    verbose: true,
  ),
);
final result = await converter.convert();
```

### 📚 Documentation

- Updated README with new features and examples
- Added comprehensive inline documentation
- Improved API documentation
- Better examples in example app

---

## [v1.5.1] - August 6, 2025

### 📝 Documentation Changes
- Updated package description in pubspec.yaml as requested by pub.dev for better compliance with publishing guidelines

## [v1.5.0] - August 6, 2025

### 🎉 Major Improvements & New Features

#### ✨ New Features
- **Configuration System**: Added `ExcelToJsonConfig` class for customizable conversion options
- **Custom Exception Handling**: Introduced `ExcelToJsonException` for better error reporting
- **Enhanced Logging**: Optional verbose logging during conversion process
- **Empty Row Handling**: Configurable option to include or exclude empty rows
- **Better Type Safety**: Improved cell value conversion with comprehensive type handling

#### 🔧 Code Improvements
- **Complete API Refactor**: More intuitive and flexible API design
- **Comprehensive Documentation**: Added detailed inline documentation for all public APIs
- **Better Error Messages**: More descriptive error messages with contextual information
- **Performance Optimization**: Streamlined conversion process with better memory usage
- **Code Quality**: Enhanced code structure with better separation of concerns

#### 📚 Documentation Enhancements
- **Comprehensive README**: Complete rewrite with examples, configuration options, and troubleshooting
- **API Documentation**: Detailed documentation for all classes and methods
- **Usage Examples**: Multiple usage patterns from basic to advanced
- **Platform Support**: Clear documentation of supported platforms and limitations

#### 🧪 Testing Improvements
- **Unit Tests**: Added comprehensive unit tests for all major components
- **Widget Tests**: Improved example app tests with better coverage
- **Example App**: Complete redesign with modern Material Design 3 UI
- **Interactive Demo**: Enhanced example with configuration options and result display

#### 🛠️ Technical Improvements
- **Better File Handling**: Enhanced file picker integration with proper error handling
- **Type Safety**: Improved type definitions and null safety
- **Memory Management**: Better handling of large Excel files
- **Cross-Platform**: Verified compatibility across all supported platforms

### 📝 Breaking Changes
- Constructor now accepts optional `ExcelToJsonConfig` parameter
- Enhanced error handling may require updating catch blocks to handle `ExcelToJsonException`
- Some internal methods have been refactored (private APIs)

### 🔄 Migration Guide
```dart
// Old usage (still supported)
final converter = ExcelToJson();
final result = await converter.convert();

// New usage with configuration
final converter = ExcelToJson(
  config: ExcelToJsonConfig(
    includeEmptyRows: true,
    verbose: true,
  ),
);
final result = await converter.convert();
```

## [v1.4.0] - 26 June 2024

### What's Changed
- Update excel dependency to version 4.0.3 by @vitoramaral10 in https://github.com/vitoramaral10/excel_to_json/pull/15
- Update contributing guidelines and code of conduct by @vitoramaral10 in https://github.com/vitoramaral10/excel_to_json/pull/15

## [v1.3.0] - 25 June 2024

## What's Changed

- Merge tag 'v1.2.0' into develop by @vitoramaral10 in https://github.com/vitoramaral10/excel_to_json/pull/13
- Update flutter by @vitoramaral10 in https://github.com/vitoramaral10/excel_to_json/pull/14
- Fixed CVE-2024-4068 by @vitoramaral10 in https://github.com/vitoramaral10/excel_to_json/security/dependabot/2

## [v1.2.0](https://github.com/vitoramaral10/excel_to_json/compare/v1.1.0...v1.2.0) - 6 September 2023

### Features

- update sdk: "&gt;=3.1.0 &lt;4.0.0" and flutter: "&gt;=1.17.0" ([`a04ea31`](https://github.com/vitoramaral10/excel_to_json/commit/a04ea31ef1287b1669a296f827a64d26586bd0cc))

## [v1.1.0](https://github.com/vitoramaral10/excel_to_json/compare/v1.0.1...v1.1.0) - 3 November 2022

### Features

- melhorias na tipagem dos valores do excel ([`13e7e2e`](https://github.com/vitoramaral10/excel_to_json/commit/13e7e2ed07b5c0e98f55115c7795b902555cf88c))

## [v1.0.1](https://github.com/vitoramaral10/excel_to_json/compare/v1.0.0...v1.0.1) - 1 November 2022

## [v1.0.0](https://github.com/vitoramaral10/excel_to_json/compare/v1.0.0-dev...v1.0.0) - 21 October 2022

## [v1.0.0-dev](https://github.com/vitoramaral10/excel_to_json/compare/v0.0.2-dev.1...v1.0.0-dev) - 21 October 2022

### Features

- ajustes de refinamento ([`ec67bb6`](https://github.com/vitoramaral10/excel_to_json/commit/ec67bb616e55e178e194eb94d322dc675a65fae0))

## [v0.0.2-dev.1]() - 14 March 2022
