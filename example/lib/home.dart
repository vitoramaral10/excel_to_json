import 'dart:convert';

import 'package:excel_to_json/excel_to_json.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? _jsonResult;
  bool _isLoading = false;
  bool _includeEmptyRows = false;
  bool _verboseLogging = false;

  Future<void> _convertExcelToJson() async {
    setState(() {
      _isLoading = true;
      _jsonResult = null;
    });

    try {
      final config = ExcelToJsonConfig(
        includeEmptyRows: _includeEmptyRows,
        verbose: _verboseLogging,
      );

      final converter = ExcelToJson(config: config);
      final jsonString = await converter.convert();

      if (jsonString != null) {
        // Pretty format the JSON for better display
        final prettyJson = const JsonEncoder.withIndent('  ').convert(
          jsonDecode(jsonString),
        );

        setState(() {
          _jsonResult = prettyJson;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Excel file converted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _jsonResult = 'No file selected or conversion cancelled.';
        });
      }
    } on ExcelToJsonException catch (e) {
      setState(() {
        _jsonResult = 'Conversion failed: ${e.message}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (kDebugMode) {
        print('ExcelToJsonException: $e');
      }
    } catch (e) {
      setState(() {
        _jsonResult = 'Unexpected error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (kDebugMode) {
        print('Unexpected error: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_jsonResult != null) {
      Clipboard.setData(ClipboardData(text: _jsonResult!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 JSON copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearResult() {
    setState(() {
      _jsonResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel to JSON Converter'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Include Empty Rows'),
                      subtitle: const Text('Include rows with all empty cells'),
                      value: _includeEmptyRows,
                      onChanged: (value) {
                        setState(() {
                          _includeEmptyRows = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Verbose Logging'),
                      subtitle: const Text('Enable detailed conversion logs'),
                      value: _verboseLogging,
                      onChanged: (value) {
                        setState(() {
                          _verboseLogging = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _convertExcelToJson,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _isLoading ? 'Converting...' : 'Select Excel File & Convert',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            if (_jsonResult != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Result:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy to clipboard',
                      ),
                      IconButton(
                        onPressed: _clearResult,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear result',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _jsonResult!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Card(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Excel file converted yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click the button above to select and convert an Excel file',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
