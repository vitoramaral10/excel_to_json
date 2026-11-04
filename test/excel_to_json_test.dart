// XML fragments are split across adjacent strings on purpose.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:excel_to_json/excel_to_json.dart';
import 'package:test/test.dart';

/// Builds an .xlsx file in memory with one sheet per entry of [sheets].
List<int> xlsx(Map<String, List<List<CellValue?>>> sheets) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet()!;
  for (final MapEntry(key: name, value: rows) in sheets.entries) {
    final sheet = excel[name];
    for (final row in rows) {
      sheet.appendRow(row);
    }
  }
  if (!sheets.containsKey(defaultSheet)) excel.delete(defaultSheet);
  return excel.encode()!;
}

/// [bytes] with each `from` in the first sheet's XML replaced by its `to`,
/// to add what Excel saves and `package:excel` cannot write.
List<int> patchSheet(List<int> bytes, Map<String, String> replacements) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final patched = Archive();
  for (final file in archive.files) {
    if (file.name == 'xl/worksheets/sheet1.xml') {
      var xml = utf8.decode(file.content as List<int>);
      replacements.forEach((from, to) {
        expect(xml, contains(from), reason: 'patch target');
        xml = xml.replaceFirst(from, to);
      });
      final data = utf8.encode(xml);
      patched.addFile(ArchiveFile(file.name, data.length, data));
    } else {
      patched.addFile(file);
    }
  }
  return ZipEncoder().encode(patched)!;
}

/// A hand-written .xlsx with one sheet `S` whose `<sheetData>` is [rows], for
/// what `package:excel` cannot write.
List<int> rawXlsx(
  String rows, {
  List<String> strings = const [],
  String numFmts = '',
  List<int> cellFormats = const [0],
  String merges = '',
  bool date1904 = false,
  String sheetState = 'visible',
  String sheetTarget = 'worksheets/sheet1.xml',
  Map<String, String?> parts = const {},
}) {
  final files = {
    'xl/workbook.xml': '<workbook xmlns:r="http://schemas.openxmlformats.org/'
        'officeDocument/2006/relationships">'
        '${date1904 ? '<workbookPr date1904="1"/>' : ''}'
        '<sheets><sheet name="S" sheetId="1" state="$sheetState" r:id="rId1"/>'
        '</sheets></workbook>',
    'xl/_rels/workbook.xml.rels': '<Relationships><Relationship Id="rId1" '
        'Target="$sheetTarget"/></Relationships>',
    'xl/worksheets/sheet1.xml':
        '<worksheet><sheetData>$rows</sheetData>$merges</worksheet>',
    'xl/sharedStrings.xml': '<sst>${strings.join()}</sst>',
    'xl/styles.xml': '<styleSheet><numFmts>$numFmts</numFmts><cellXfs>'
        '${[for (final id in cellFormats) '<xf numFmtId="$id"/>'].join()}'
        '</cellXfs></styleSheet>',
  };
  // `parts` adds or replaces files; a null value removes one.
  for (final MapEntry(key: name, value: xml) in parts.entries) {
    if (xml == null) {
      files.remove(name);
    } else {
      files[name] = xml;
    }
  }
  final archive = Archive();
  files.forEach((name, xml) {
    final data = utf8.encode(xml);
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  return ZipEncoder().encode(archive)!;
}

void main() {
  const converter = ExcelToJson();

  group('toMap', () {
    test('turns each row into a map keyed by the header', () {
      final bytes = xlsx({
        'People': [
          [TextCellValue('Name'), TextCellValue('Age'), TextCellValue('Admin')],
          [
            TextCellValue('Ana'),
            const IntCellValue(30),
            const BoolCellValue(true),
          ],
          [
            TextCellValue('Bruno'),
            const IntCellValue(41),
            const BoolCellValue(false),
          ],
        ],
      });

      expect(converter.toMap(bytes), {
        'People': [
          {'Name': 'Ana', 'Age': 30, 'Admin': true},
          {'Name': 'Bruno', 'Age': 41, 'Admin': false},
        ],
      });
    });

    test('keeps every sheet', () {
      final bytes = xlsx({
        'A': [
          [TextCellValue('x')],
          [const IntCellValue(1)],
        ],
        'B': [
          [TextCellValue('y')],
          [const IntCellValue(2)],
        ],
      });

      expect(converter.toMap(bytes), {
        'A': [
          {'x': 1},
        ],
        'B': [
          {'y': 2},
        ],
      });
    });

    test('a blank header cell keeps its data under the column letter', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('Name'), null, TextCellValue('Age')],
          [
            TextCellValue('Ana'),
            TextCellValue('ignored'),
            const IntCellValue(30),
          ],
        ],
      });

      expect(converter.toMap(bytes)['S'], [
        {'Name': 'Ana', 'B': 'ignored', 'Age': 30},
      ]);
    });

    test('a blank header column with no data is left out', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('Name'), null, TextCellValue('Age')],
          [TextCellValue('Ana'), null, const IntCellValue(30)],
        ],
      });

      expect(converter.toMap(bytes)['S'], [
        {'Name': 'Ana', 'Age': 30},
      ]);
    });

    test('missing cells are null', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('a'), TextCellValue('b'), TextCellValue('c')],
          [const IntCellValue(1)],
          [null, null, const IntCellValue(3)],
        ],
      });

      expect(converter.toMap(bytes)['S'], [
        {'a': 1, 'b': null, 'c': null},
        {'a': null, 'b': null, 'c': 3},
      ]);
    });

    test('skips empty rows by default', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('a')],
          [const IntCellValue(1)],
          [null],
          [const IntCellValue(2)],
        ],
      });

      expect(converter.toMap(bytes)['S'], [
        {'a': 1},
        {'a': 2},
      ]);
    });

    test('keeps empty rows with includeEmptyRows', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('a')],
          [const IntCellValue(1)],
          [null],
          [const IntCellValue(2)],
        ],
      });

      const keep = ExcelToJson(
        config: ExcelToJsonConfig(includeEmptyRows: true),
      );
      expect(keep.toMap(bytes)['S'], [
        {'a': 1},
        {'a': null},
        {'a': 2},
      ]);
    });

    test('numbers in the header become text keys', () {
      final bytes = xlsx({
        'S': [
          [const IntCellValue(2024), const DoubleCellValue(1.5)],
          [TextCellValue('x'), TextCellValue('y')],
        ],
      });

      expect(converter.toMap(bytes)['S'], [
        {'2024': 'x', '1.5': 'y'},
      ]);
    });

    test('a sheet with only a header or nothing has no rows', () {
      final bytes = xlsx({
        'Header': [
          [TextCellValue('a')],
        ],
        'Empty': [],
      });

      expect(
        converter.toMap(bytes),
        {'Header': <Object?>[], 'Empty': <Object?>[]},
      );
    });

    test('doubles and formulas', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('price'), TextCellValue('total')],
          [const DoubleCellValue(9.5), const FormulaCellValue('SUM(A2:A3)')],
        ],
      });

      expect(converter.toMap(bytes)['S'], [
        {'price': 9.5, 'total': 'SUM(A2:A3)'},
      ]);
    });

    group('dates and times', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('day'), TextCellValue('at'), TextCellValue('time')],
          [
            const DateCellValue(year: 2026, month: 11, day: 4),
            const DateTimeCellValue(
              year: 2026,
              month: 11,
              day: 4,
              hour: 13,
              minute: 30,
            ),
            const TimeCellValue(hour: 8, minute: 15),
          ],
        ],
      });

      test('are ISO 8601 strings by default', () {
        expect(converter.toMap(bytes)['S'], [
          {
            'day': '2026-11-04T00:00:00.000Z',
            'at': '2026-11-04T13:30:00.000Z',
            'time': '08:15:00',
          },
        ]);
      });

      test('are DateTime and Duration without useDateTimeStrings', () {
        const typed = ExcelToJson(
          config: ExcelToJsonConfig(useDateTimeStrings: false),
        );
        expect(typed.toMap(bytes)['S'], [
          {
            'day': DateTime.utc(2026, 11, 4),
            'at': DateTime.utc(2026, 11, 4, 13, 30),
            'time': const Duration(hours: 8, minutes: 15),
          },
        ]);
      });

      test('are strings in toJson even without useDateTimeStrings', () {
        const typed = ExcelToJson(
          config: ExcelToJsonConfig(useDateTimeStrings: false),
        );
        expect(jsonDecode(typed.toJson(bytes)), {
          'S': [
            {
              'day': '2026-11-04T00:00:00.000Z',
              'at': '2026-11-04T13:30:00.000Z',
              'time': '08:15:00',
            },
          ],
        });
      });
    });

    test('unreadable bytes throw ExcelToJsonException', () {
      for (final bytes in [
        <int>[],
        [0x50, 0x4b, 0x03, 0x04, 1, 2, 3], // a broken zip
        [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1], // legacy .xls
      ]) {
        expect(
          () => converter.toMap(bytes),
          throwsA(isA<ExcelToJsonException>()),
          reason: '$bytes',
        );
      }
    });
  });

  group('formulas', () {
    List<int> withFormulas() => xlsx({
          'Sheet1': [
            [TextCellValue('total'), TextCellValue('today')],
            [
              const FormulaCellValue('SUM(1,2)'),
              const FormulaCellValue('TODAY()'),
            ],
          ],
        });

    test('give the result Excel saved', () {
      final bytes = patchSheet(withFormulas(), {
        '<f>SUM(1,2)</f><v></v>': '<f>SUM(1,2)</f><v>3</v>',
        '<f>TODAY()</f><v></v>': '<f>TODAY()</f><v>4.5</v>',
      });

      expect(converter.toMap(bytes)['Sheet1'], [
        {'total': 3, 'today': 4.5},
      ]);
    });

    test('a date formula gives a date when the cell is formatted as one', () {
      final excel = Excel.createExcel();
      excel['Sheet1']
        ..appendRow([TextCellValue('today')])
        ..updateCell(
          CellIndex.indexByString('A2'),
          const FormulaCellValue('TODAY()'),
          cellStyle: CellStyle(numberFormat: NumFormat.standard_14),
        );
      final bytes = patchSheet(excel.encode()!, {
        '<f>TODAY()</f><v></v>': '<f>TODAY()</f><v>46330</v>',
      });

      expect(converter.toMap(bytes)['Sheet1'], [
        {'today': '2026-11-04T00:00:00.000Z'},
      ]);
    });

    test('text, boolean and error results', () {
      final bytes = patchSheet(withFormulas(), {
        '<c r="A2" s="1"><f>SUM(1,2)</f><v></v>':
            '<c r="A2" s="1" t="str"><f>A1&amp;"!"</f><v>hi!</v>',
        '<c r="B2" s="1"><f>TODAY()</f><v></v>':
            '<c r="B2" s="1" t="b"><f>1=1</f><v>1</v>',
      });

      expect(converter.toMap(bytes)['Sheet1'], [
        {'total': 'hi!', 'today': true},
      ]);
      final error = patchSheet(withFormulas(), {
        '<c r="A2" s="1"><f>SUM(1,2)</f><v></v>':
            '<c r="A2" s="1" t="e"><f>1/0</f><v>#DIV/0!</v>',
      });
      expect(converter.toMap(error)['Sheet1']!.first['total'], '#DIV/0!');
    });

    test('without a saved result give the formula text', () {
      expect(converter.toMap(withFormulas())['Sheet1'], [
        {'total': 'SUM(1,2)', 'today': 'TODAY()'},
      ]);
    });

    test('give the formula text with formulaResults: false', () {
      final bytes = patchSheet(withFormulas(), {
        '<f>SUM(1,2)</f><v></v>': '<f>SUM(1,2)</f><v>3</v>',
      });
      const text = ExcelToJson(
        config: ExcelToJsonConfig(formulaResults: false),
      );

      expect(text.toMap(bytes)['Sheet1']!.first['total'], 'SUM(1,2)');
    });
  });

  group('headerRow', () {
    // A title in row 1, row 2 blank, the header in row 3.
    final titled = () {
      final excel = Excel.createExcel();
      final sheet = excel['S'];
      void put(String cell, CellValue value) =>
          sheet.updateCell(CellIndex.indexByString(cell), value);
      put('A1', TextCellValue('Monthly report'));
      put('A3', TextCellValue('Name'));
      put('B3', TextCellValue('Age'));
      put('A4', TextCellValue('Ana'));
      put('B4', const IntCellValue(30));
      excel.delete('Sheet1');
      return excel.encode()!;
    }();

    test('skips the rows above the header', () {
      const converter = ExcelToJson(config: ExcelToJsonConfig(headerRow: 3));
      expect(converter.toMap(titled)['S'], [
        {'Name': 'Ana', 'Age': 30},
      ]);
    });

    test('past the last row gives no rows', () {
      const converter = ExcelToJson(config: ExcelToJsonConfig(headerRow: 9));
      expect(converter.toMap(titled)['S'], isEmpty);
    });

    test('null uses column letters and keeps every row', () {
      const converter = ExcelToJson(config: ExcelToJsonConfig(headerRow: null));
      expect(converter.toMap(titled)['S'], [
        {'A': 'Monthly report', 'B': null},
        {'A': 'Name', 'B': 'Age'},
        {'A': 'Ana', 'B': 30},
      ]);
    });

    test('below 1 is rejected', () {
      expect(
        () =>
            ExcelToJson(config: ExcelToJsonConfig(headerRow: 0)).toMap(titled),
        throwsA(anyOf(isA<ArgumentError>(), isA<AssertionError>())),
      );
    });
  });

  group('fillMergedCells', () {
    List<int> merged() {
      final excel = Excel.createExcel();
      excel['Sheet1']
        ..appendRow([TextCellValue('Region'), TextCellValue('City')])
        ..appendRow([TextCellValue('South'), TextCellValue('Curitiba')])
        ..appendRow([null, TextCellValue('Porto Alegre')])
        ..merge(
          CellIndex.indexByString('A2'),
          CellIndex.indexByString('A3'),
        );
      return excel.encode()!;
    }

    test('off: only the first cell of a merge has the value', () {
      expect(converter.toMap(merged())['Sheet1'], [
        {'Region': 'South', 'City': 'Curitiba'},
        {'Region': null, 'City': 'Porto Alegre'},
      ]);
    });

    test('on: every merged cell has the value', () {
      const fill = ExcelToJson(
        config: ExcelToJsonConfig(fillMergedCells: true),
      );
      expect(fill.toMap(merged())['Sheet1'], [
        {'Region': 'South', 'City': 'Curitiba'},
        {'Region': 'South', 'City': 'Porto Alegre'},
      ]);
    });
  });

  group('keys', () {
    List<int> headed(List<String> names) => xlsx({
          'S': [
            [for (final name in names) TextCellValue(name)],
            [for (var i = 0; i < names.length; i++) IntCellValue(i)],
          ],
        });

    test('repeated names get a suffix', () {
      expect(converter.toMap(headed(['Name', 'Name', 'Name']))['S'], [
        {'Name': 0, 'Name_2': 1, 'Name_3': 2},
      ]);
    });

    test('whitespace is trimmed and collapsed', () {
      expect(converter.toMap(headed(['  Data de\n Nascimento ']))['S'], [
        {'Data de Nascimento': 0},
      ]);
    });

    test('snakeCase and camelCase drop accents and symbols', () {
      final bytes = headed(['Data de Nascimento', 'Endereço (Rua)', 'CPF']);
      const snake = ExcelToJson(
        config: ExcelToJsonConfig(keyStyle: KeyStyle.snakeCase),
      );
      const camel = ExcelToJson(
        config: ExcelToJsonConfig(keyStyle: KeyStyle.camelCase),
      );

      expect(snake.toMap(bytes)['S']!.single.keys, [
        'data_de_nascimento',
        'endereco_rua',
        'cpf',
      ]);
      expect(camel.toMap(bytes)['S']!.single.keys, [
        'dataDeNascimento',
        'enderecoRua',
        'cpf',
      ]);
    });

    test('keys keep letters of any script', () {
      const snake = ExcelToJson(
        config: ExcelToJsonConfig(keyStyle: KeyStyle.snakeCase),
      );
      const camel = ExcelToJson(
        config: ExcelToJsonConfig(keyStyle: KeyStyle.camelCase),
      );
      final bytes = headed(['Имя Фамилия', '名前', 'Łódź Größe']);
      expect(snake.toMap(bytes)['S']!.single.keys, [
        'имя_фамилия',
        '名前',
        'łodź_große', // ó and ö fold; ź and ß stay
      ]);
      expect(camel.toMap(bytes)['S']!.single.keys.first, 'имяФамилия');
    });

    test('real names take precedence over column letters', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('B'), null],
          [const IntCellValue(1), const IntCellValue(2)],
        ],
      });
      expect(converter.toMap(bytes)['S'], [
        {'B': 1, 'B_2': 2},
      ]);
      final reverse = xlsx({
        'S': [
          [null, TextCellValue('A')],
          [const IntCellValue(1), const IntCellValue(2)],
        ],
      });
      expect(converter.toMap(reverse)['S'], [
        {'A_2': 1, 'A': 2},
      ]);
    });

    test('a date header gives the same key with either date option', () {
      final bytes = xlsx({
        'S': [
          [const DateCellValue(year: 2024, month: 1, day: 15)],
          [const IntCellValue(1)],
        ],
      });
      const typed = ExcelToJson(
        config: ExcelToJsonConfig(useDateTimeStrings: false),
      );
      expect(
        converter.toMap(bytes)['S']!.single.keys,
        typed.toMap(bytes)['S']!.single.keys,
      );
      expect(
        typed.toMap(bytes)['S']!.single.keys,
        ['2024-01-15T00:00:00.000Z'],
      );
    });

    test('a header with no letters or digits falls back to the letter', () {
      const snake = ExcelToJson(
        config: ExcelToJsonConfig(keyStyle: KeyStyle.snakeCase),
      );
      expect(snake.toMap(headed(['Name', '???']))['S'], [
        {'name': 0, 'B': 1},
      ]);
    });

    test('column letters go past Z', () {
      const letters = ExcelToJson(config: ExcelToJsonConfig(headerRow: null));
      final bytes = xlsx({
        'S': [
          [for (var i = 0; i < 28; i++) IntCellValue(i)],
        ],
      });
      expect(
        letters.toMap(bytes)['S']!.single.keys.skip(24),
        ['Y', 'Z', 'AA', 'AB'],
      );
    });
  });

  group('sheets', () {
    final bytes = xlsx({
      'A': [
        [TextCellValue('x')],
        [const IntCellValue(1)],
      ],
      'B': [
        [TextCellValue('y')],
        [const IntCellValue(2)],
      ],
    });

    test('converts only the sheets asked for', () {
      const onlyB = ExcelToJson(config: ExcelToJsonConfig(sheets: ['B']));
      expect(onlyB.toMap(bytes).keys, ['B']);
    });

    test('a missing sheet names the ones the file has', () {
      const missing = ExcelToJson(config: ExcelToJsonConfig(sheets: ['C']));
      expect(
        () => missing.toMap(bytes),
        throwsA(
          isA<ExcelToJsonException>().having(
            (e) => e.message,
            'message',
            'Sheet "C" not found; the file has: A, B',
          ),
        ),
      );
    });
  });

  group('CSV', () {
    test('is detected and read as text', () {
      expect(converter.toMap(utf8.encode('Name,CEP\nAna,01310100\n')), {
        'Sheet1': [
          {'Name': 'Ana', 'CEP': '01310100'},
        ],
      });
    });

    test('semicolons, quotes, line breaks and empty fields', () {
      const csv = 'Nome;Obs;Valor\r\n'
          '"Silva; Ana";"diz ""oi""\nduas linhas";12,5\r\n'
          'Bruno;;\r\n';
      expect(converter.toMap(utf8.encode(csv))['Sheet1'], [
        {'Nome': 'Silva; Ana', 'Obs': 'diz "oi"\nduas linhas', 'Valor': '12,5'},
        {'Nome': 'Bruno', 'Obs': null, 'Valor': null},
      ]);
    });

    test('decimal commas and a title do not fool the delimiter', () {
      const csv = 'Relatório de pesos\n'
          'Nome;Peso;Altura\n'
          'Ana;61,5;1,68\n'
          'Bruno;80,2;1,80\n';
      const header = ExcelToJson(config: ExcelToJsonConfig(headerRow: 2));
      expect(header.toMap(utf8.encode(csv))['Sheet1'], [
        {'Nome': 'Ana', 'Peso': '61,5', 'Altura': '1,68'},
        {'Nome': 'Bruno', 'Peso': '80,2', 'Altura': '1,80'},
      ]);
    });

    test('delimiters inside quotes are not counted', () {
      const csv = '"Silva, Ana";"Rua A, 10"\n"Souza, Bruno";"Rua B, 20"\n';
      const raw = ExcelToJson(config: ExcelToJsonConfig(headerRow: null));
      expect(raw.toMap(utf8.encode(csv))['Sheet1'], [
        {'A': 'Silva, Ana', 'B': 'Rua A, 10'},
        {'A': 'Souza, Bruno', 'B': 'Rua B, 20'},
      ]);
    });

    test('tabs, a BOM and no final newline', () {
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('a\tb\n1\t2')];
      expect(converter.toMap(bytes)['Sheet1'], [
        {'a': '1', 'b': '2'},
      ]);
    });

    test('Windows-1252 files keep accents, € and curly quotes', () {
      final bytes = [
        ...latin1.encode('Cidade;Preço;Obs\nSão Paulo;'),
        0x80, ...latin1.encode('10;'), 0x93, ...latin1.encode('ok'), 0x94,
        0x0A, //
      ];
      expect(converter.toMap(bytes)['Sheet1'], [
        {'Cidade': 'São Paulo', 'Preço': '€10', 'Obs': '“ok”'},
      ]);
    });

    test('a quote inside an unquoted field is text', () {
      final bytes = utf8.encode('Item,Size\nMonitor 24",100\nCable,5\n');
      expect(converter.toMap(bytes)['Sheet1'], [
        {'Item': 'Monitor 24"', 'Size': '100'},
        {'Item': 'Cable', 'Size': '5'},
      ]);
    });

    test('a quoted empty field is an empty string', () {
      expect(converter.toMap(utf8.encode('a,b\n"",x\n'))['Sheet1'], [
        {'a': '', 'b': 'x'},
      ]);
    });

    test('follows headerRow and keyStyle like .xlsx', () {
      const config = ExcelToJsonConfig(
        headerRow: 2,
        keyStyle: KeyStyle.snakeCase,
      );
      expect(
        const ExcelToJson(config: config)
            .toMap(utf8.encode('Relatório\nNome Completo\nAna\n'))['Sheet1'],
        [
          {'nome_completo': 'Ana'},
        ],
      );
    });
  });

  group('xlsx reader', () {
    const raw = ExcelToJson(config: ExcelToJsonConfig(headerRow: null));
    Map<String, Object?> firstRow(List<int> bytes) =>
        raw.toMap(bytes)['S']!.first;

    test('repeated shared strings keep their positions', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
        '<c r="C1" t="s"><v>2</v></c></row>',
        strings: [
          '<si><t>x</t></si>',
          '<si><t>x</t></si>',
          '<si><t>y</t></si>',
        ],
      );
      expect(firstRow(bytes), {'A': 'x', 'B': 'x', 'C': 'y'});
    });

    test('rich text, inline strings and phonetic hints', () {
      const rich = '<si><r><t>bold </t></r><r><t>plain</t></r>'
          '<rPh><t>ignored</t></rPh></si>';
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" t="s"><v>0</v></c>'
        '<c r="B1" t="inlineStr"><is><t>inline</t></is></c></row>',
        strings: [rich],
      );
      expect(firstRow(bytes), {'A': 'bold plain', 'B': 'inline'});
    });

    test('cells without a reference follow the previous one', () {
      final bytes = rawXlsx(
        '<row><c><v>1</v></c><c><v>2</v></c></row>'
        '<row><c r="B2"><v>3</v></c><c><v>4</v></c></row>',
      );
      expect(raw.toMap(bytes)['S'], [
        {'A': 1, 'B': 2, 'C': null},
        {'A': null, 'B': 3, 'C': 4},
      ]);
    });

    test('numbers, booleans, errors and ISO dates', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1"><v>42</v></c><c r="B1"><v>1.5E2</v></c>'
        '<c r="C1"><v>0.25</v></c><c r="D1" t="b"><v>0</v></c>'
        '<c r="E1" t="e"><v>#N/A</v></c>'
        '<c r="F1" t="d"><v>2026-11-04T10:00:00Z</v></c></row>',
      );
      expect(firstRow(bytes), {
        'A': 42,
        'B': 150,
        'C': 0.25,
        'D': false,
        'E': '#N/A',
        'F': '2026-11-04T10:00:00.000Z',
      });
    });

    test('number formats decide dates, times and durations', () {
      final bytes = rawXlsx(
        '<row r="1">'
        '<c r="A1" s="1"><v>46330</v></c>' // built-in date
        '<c r="B1" s="2"><v>46330.5625</v></c>' // custom date and time
        '<c r="C1" s="3"><v>46330.5625</v></c>' // time of day only
        '<c r="D1" s="4"><v>1.25</v></c>' // elapsed hours
        '<c r="E1" s="5"><v>15.99</v></c>' // currency, not a date
        '<c r="F1" s="6"><v>0.05</v></c>' // percent
        '<c r="G1" s="7"><v>46330</v></c>' // month and year
        '<c r="H1" s="8"><v>2</v></c>' // "[h]" as literal text
        '</row>',
        numFmts: r'<numFmt numFmtId="164" formatCode="dd/mm/yyyy\ hh:mm"/>'
            r'<numFmt numFmtId="165" formatCode="[$R$-416]\ #,##0.00"/>'
            '<numFmt numFmtId="166" formatCode="mmm/yy"/>'
            r'<numFmt numFmtId="167" formatCode="0\ &quot;[h]&quot;"/>',
        cellFormats: [0, 14, 164, 21, 46, 165, 9, 166, 167],
      );
      expect(firstRow(bytes), {
        'A': '2026-11-04T00:00:00.000Z',
        'B': '2026-11-04T13:30:00.000Z',
        'C': '13:30:00',
        'D': '30:00:00',
        'E': 15.99,
        'F': 0.05,
        'G': '2026-11-04T00:00:00.000Z',
        'H': 2,
      });
    });

    test('dates and times as DateTime and Duration', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" s="1"><v>46330</v></c>'
        '<c r="B1" s="2"><v>0.5</v></c><c r="C1" s="3"><v>1.25</v></c></row>',
        cellFormats: [0, 14, 21, 46],
      );
      const typed = ExcelToJson(
        config: ExcelToJsonConfig(headerRow: null, useDateTimeStrings: false),
      );
      expect(typed.toMap(bytes)['S']!.first, {
        'A': DateTime.utc(2026, 11, 4),
        'B': const Duration(hours: 12),
        'C': const Duration(hours: 30),
      });
    });

    test('early 1900 dates skip the leap day Excel invented', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" s="1"><v>1</v></c>'
        '<c r="B1" s="1"><v>59</v></c><c r="C1" s="1"><v>60</v></c>'
        '<c r="D1" s="1"><v>61</v></c></row>',
        cellFormats: [0, 14],
      );
      expect(firstRow(bytes), {
        'A': '1900-01-01T00:00:00.000Z',
        'B': '1900-02-28T00:00:00.000Z',
        'C': '1900-02-28T00:00:00.000Z', // Excel's invented 1900-02-29
        'D': '1900-03-01T00:00:00.000Z',
      });
    });

    test('the 1904 date system', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" s="1"><v>0</v></c></row>',
        cellFormats: [0, 14],
        date1904: true,
      );
      expect(firstRow(bytes), {'A': '1904-01-01T00:00:00.000Z'});
    });

    test('a built-in format id declared again keeps its own code', () {
      // Writers such as Apache POI declare built-in ids; package:excel refused
      // these files.
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" s="1"><v>15.99</v></c></row>',
        numFmts: r'<numFmt numFmtId="8" formatCode="&quot;$&quot;#,##0.00"/>',
        cellFormats: [0, 8],
      );
      expect(firstRow(bytes), {'A': 15.99});
    });

    test('a shared formula gives its saved result', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1"><f t="shared" ref="A1:A2" si="0">ROW()</f>'
        '<v>1</v></c></row>'
        '<row r="2"><c r="A2"><f t="shared" si="0"/><v>2</v></c></row>',
      );
      expect(raw.toMap(bytes)['S'], [
        {'A': 1},
        {'A': 2},
      ]);
    });

    test('merges past the last written cell are filled too', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1"><v>7</v></c></row>',
        merges: '<mergeCells><mergeCell ref="A1:B2"/></mergeCells>',
      );
      const fill = ExcelToJson(
        config: ExcelToJsonConfig(headerRow: null, fillMergedCells: true),
      );
      expect(fill.toMap(bytes)['S'], [
        {'A': 7, 'B': 7},
        {'A': 7, 'B': 7},
      ]);
    });

    test('hidden sheets can be left out', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1"><v>1</v></c></row>',
        sheetState: 'hidden',
      );
      const skip = ExcelToJson(
        config: ExcelToJsonConfig(headerRow: null, includeHiddenSheets: false),
      );
      const named = ExcelToJson(
        config: ExcelToJsonConfig(
          headerRow: null,
          includeHiddenSheets: false,
          sheets: ['S'],
        ),
      );

      expect(raw.toMap(bytes).keys, ['S']);
      expect(skip.toMap(bytes), isEmpty);
      expect(named.toMap(bytes).keys, ['S']);
    });

    test('relative and absolute sheet targets', () {
      for (final target in [
        '../xl/worksheets/sheet1.xml',
        './worksheets/sheet1.xml',
        '/xl/worksheets/sheet1.xml',
      ]) {
        final bytes = rawXlsx(
          '<row r="1"><c r="A1"><v>1</v></c></row>',
          sheetTarget: target,
        );
        expect(firstRow(bytes), {'A': 1}, reason: target);
      }
    });

    test('elements with a namespace prefix', () {
      // As written by the .NET Open XML SDK.
      final plain = rawXlsx(
        '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" s="1"><v>46330</v>'
        '</c></row>',
        strings: ['<si><t>x</t></si>'],
        cellFormats: [0, 14],
      );
      final archive = ZipDecoder().decodeBytes(plain);
      final prefixed = Archive();
      for (final file in archive.files) {
        final xml = utf8.decode(file.content as List<int>).replaceAllMapped(
              RegExp('<(/?)([A-Za-z])'),
              (m) => '<${m[1]}x:${m[2]}',
            );
        final data = utf8.encode(xml);
        prefixed.addFile(ArchiveFile(file.name, data.length, data));
      }

      expect(firstRow(ZipEncoder().encode(prefixed)!), {
        'A': 'x',
        'B': '2026-11-04T00:00:00.000Z',
      });
    });

    test('whitespace around values, empty indexes and one-cell merges', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1"><v> 42 </v></c><c r="B1" t="s"><v></v></c>'
        '<c r="C1"><v>5</v></c>'
        '<c r="D1" t="str"><f>" x "</f><v> x </v></c></row>',
        merges: '<mergeCells><mergeCell ref="C1"/></mergeCells>',
      );
      const fill = ExcelToJson(
        config: ExcelToJsonConfig(headerRow: null, fillMergedCells: true),
      );
      // B holds no data, so it is left out like any empty column.
      // A text result keeps its spaces.
      expect(fill.toMap(bytes)['S']!.first, {'A': 42, 'C': 5, 'D': ' x '});
    });

    test('an empty text result is an empty string', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" t="str"><f>IF(1=1,"","x")</f><v></v></c>'
        '<c r="B1" t="str"><f>""</f><v/></c></row>',
      );
      expect(firstRow(bytes), {'A': '', 'B': ''});
    });

    test('Excel escapes such as _x000D_ are decoded', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" t="s"><v>0</v></c>'
        '<c r="B1" t="inlineStr"><is><t>a_x0009_b</t></is></c></row>',
        strings: ['<si><t>L1_x000D_\nL2 _x005F_x0041_</t></si>'],
      );
      expect(firstRow(bytes), {'A': 'L1\r\nL2 _x0041_', 'B': 'a\tb'});
    });

    test('ISO date cells are UTC, and may hold only a time', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" t="d"><v>2024-01-15T10:30:00</v></c>'
        '<c r="B1" t="d"><v>2024-01-15T10:30:00+02:00</v></c>'
        '<c r="C1" t="d"><v>10:30:00</v></c></row>',
      );
      expect(firstRow(bytes), {
        'A': '2024-01-15T10:30:00.000Z',
        'B': '2024-01-15T08:30:00.000Z',
        'C': '10:30:00',
      });
    });

    test('East Asian built-in date formats', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" s="1"><v>45306</v></c></row>',
        cellFormats: [0, 31],
      );
      expect(firstRow(bytes), {'A': '2024-01-15T00:00:00.000Z'});
    });

    test('conditional formats do not replace the real one', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" s="1"><v>45306</v></c></row>',
        numFmts: '<numFmt numFmtId="164" formatCode="dd/mm/yyyy"/>',
        cellFormats: [0, 164],
        parts: {
          'xl/styles.xml': '<styleSheet><numFmts>'
              '<numFmt numFmtId="164" formatCode="dd/mm/yyyy"/></numFmts>'
              '<cellXfs><xf numFmtId="0"/><xf numFmtId="164"/></cellXfs>'
              '<dxfs><dxf><numFmt numFmtId="164" formatCode="0.00"/></dxf>'
              '</dxfs></styleSheet>',
        },
      );
      expect(firstRow(bytes), {'A': '2024-01-15T00:00:00.000Z'});
    });

    test('parts are found through their relationships', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" t="s"><v>0</v></c></row>',
        parts: {
          '_rels/.rels': '<Relationships><Relationship Id="r1" Type="http://'
              'schemas.openxmlformats.org/officeDocument/2006/relationships/'
              'officeDocument" Target="book/main.xml"/></Relationships>',
          'xl/workbook.xml': null,
          'xl/_rels/workbook.xml.rels': null,
          'xl/sharedStrings.xml': null,
          'book/main.xml': '<workbook xmlns:r="r"><sheets>'
              '<sheet name="S" r:id="rId1"/></sheets></workbook>',
          'book/_rels/main.xml.rels': '<Relationships>'
              '<Relationship Id="rId1" Type=".../worksheet" '
              r'Target="..\xl\worksheets\sheet1.xml"/>'
              '<Relationship Id="rId2" Type=".../sharedStrings" '
              'Target="Strings.xml"/></Relationships>',
          'book/Strings.xml': '<sst><si><t>found</t></si></sst>',
        },
      );
      expect(firstRow(bytes), {'A': 'found'});
    });

    test('a sheet whose part is missing throws', () {
      final bytes = rawXlsx('', sheetTarget: 'worksheets/sheet9.xml');
      expect(
        () => raw.toMap(bytes),
        throwsA(
          isA<ExcelToJsonException>()
              .having((e) => e.message, 'message', 'Could not read sheet "S"'),
        ),
      );
    });

    test('merges keep values already in their cells', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1"><v>1</v></c></row>'
        '<row r="2"><c r="A2"><v>2</v></c></row>'
        '<row r="3"><c r="B3"><v>5</v></c></row>',
        merges: '<mergeCells><mergeCell ref="A2:A1"/>'
            '<mergeCell ref="A3:B3"/></mergeCells>',
      );
      const fill = ExcelToJson(
        config: ExcelToJsonConfig(headerRow: null, fillMergedCells: true),
      );
      expect(fill.toMap(bytes)['S'], [
        {'A': 1, 'B': null},
        {'A': 2, 'B': null}, // reversed range, filled where empty only
        {'A': null, 'B': 5}, // empty top-left: nothing to copy
      ]);
    });

    test('negative durations and times just before midnight', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" s="1"><v>-0.0208333333</v></c>'
        '<c r="B1" s="2"><v>0.99999999999</v></c></row>',
        cellFormats: [0, 46, 21],
      );
      expect(firstRow(bytes), {'A': '-00:30:00', 'B': '00:00:00'});
    });

    test('booleans written as words and styles out of range', () {
      final bytes = rawXlsx(
        '<row r="1"><c r="A1" t="b"><v>TRUE</v></c>'
        '<c r="B1" s="-1"><v>7</v></c></row>',
      );
      expect(firstRow(bytes), {'A': true, 'B': 7});
    });

    test('a broken sheet throws ExcelToJsonException', () {
      final bytes = rawXlsx('<row r="1"><c r="A1" t="s"><v>5</v></c></row>');
      expect(
        () => raw.toMap(bytes),
        throwsA(
          isA<ExcelToJsonException>()
              .having((e) => e.message, 'message', 'Could not read sheet "S"'),
        ),
      );
    });
  });

  group('toJson', () {
    test('encodes text, numbers and booleans', () {
      final bytes = xlsx({
        'S': [
          [TextCellValue('Name'), TextCellValue('Age')],
          [TextCellValue('Ana'), const IntCellValue(30)],
        ],
      });

      expect(converter.toJson(bytes), '{"S":[{"Name":"Ana","Age":30}]}');
    });
  });

  group('ExcelToJsonException', () {
    test('toString shows the cause', () {
      expect(
        const ExcelToJsonException('bad', FormatException('zip')).toString(),
        'ExcelToJsonException: bad (Caused by: FormatException: zip)',
      );
      expect(
        const ExcelToJsonException('bad').toString(),
        'ExcelToJsonException: bad',
      );
    });
  });
}
