import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Runs the `excel-to-json` command with [args].
Future<ProcessResult> cli(List<String> args) => Process.run(
      Platform.resolvedExecutable,
      ['run', 'bin/excel_to_json.dart', ...args],
    );

void main() {
  late Directory dir;
  late String csv;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('excel_to_json_cli');
    csv = '${dir.path}/people.csv';
    File(csv).writeAsStringSync('Report\nFull Name;Age\nAna;30\n');
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  test('converts with the options given', () async {
    final result = await cli([csv, '--header-row', '2', '--keys', 'snake']);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(jsonDecode(result.stdout as String), {
      'Sheet1': [
        {'full_name': 'Ana', 'age': '30'},
      ],
    });
  });

  test('bad options and missing files fail with a message', () async {
    final badOption = await cli([csv, '--keys', 'kebab']);
    expect(badOption.exitCode, 64);
    expect(badOption.stderr, contains('unknown key style "kebab"'));

    final missing = await cli(['${dir.path}/nope.xlsx']);
    expect(missing.exitCode, 66);

    final noSheet = await cli([csv, '--sheet', 'Sales']);
    expect(noSheet.exitCode, 65);
    expect(noSheet.stderr, contains('Sheet "Sales" not found'));
  });

  test('--option=value, -- and a missing value', () async {
    final inline = await cli([csv, '--header-row=2', '--keys=camel']);
    expect(jsonDecode(inline.stdout as String), {
      'Sheet1': [
        {'fullName': 'Ana', 'age': '30'},
      ],
    });

    final dashed = await cli(['--header-row', '2', '--', csv]);
    expect(dashed.exitCode, 0, reason: '${dashed.stderr}');

    final missing = await cli([csv, '--sheet', '--pretty']);
    expect(missing.exitCode, 64);
    expect(missing.stderr, contains('--sheet needs a value'));
  });

  test('--help prints the usage', () async {
    final result = await cli(['--help']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: excel-to-json <file> [options]'));
  });
}
