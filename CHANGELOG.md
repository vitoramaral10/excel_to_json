# Changelog

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
