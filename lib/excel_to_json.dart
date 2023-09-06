import 'dart:convert';
import 'dart:developer';

import 'package:excel_facility/excel_facility.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// This is the main project class.
class ExcelToJson {
  /// Use this method to convert the file to a json.
  Future<String?> convert() async {
    final Excel? excel = await _getFile();

    if (excel != null) {
      final List<String> tables = _getTables(excel);

      int index = 0;
      final Map<String, dynamic> json = {};

      for (final String table in tables) {
        List<Data?> keys = [];
        json.addAll({table: []});

        for (final List<Data?> row in excel.tables[table]?.rows ?? []) {
          try {
            if (index == 0) {
              keys = row;
              index++;
            } else {
              final Map<String, dynamic> temp = _getRows(keys, row);

              json[table].add(temp);
            }
          } on Exception catch (ex) {
            log(ex.toString());

            rethrow;
          }
        }
        index = 0;
      }

      return jsonEncode(json);
    }

    return null;
  }

  Map<String, dynamic> _getRows(final List<Data?> keys, final List<Data?> row) {
    final Map<String, dynamic> temp = {};
    int index = 0;
    String tk = '';

    for (final Data? key in keys) {
      if (key != null && key.value != null) {
        tk = key.value.toString();

        if ([
          CellType.String,
          CellType.int,
          CellType.double,
          CellType.bool,
        ].contains(row[index]?.cellType)) {
          if (row[index]?.value == 'true') {
            temp[tk] = true;
          } else if (row[index]?.value == 'false') {
            temp[tk] = false;
          } else {
            temp[tk] = row[index]?.value;
          }
        } else if (row[index]?.cellType == CellType.Formula) {
          temp[tk] = row[index]?.value.toString();
        }

        index++;
      }
    }

    return temp;
  }

  List<String> _getTables(final Excel excel) {
    final List<String> keys = [];

    for (final String table in excel.tables.keys) {
      keys.add(table);
    }

    return keys;
  }

  Future<Excel?> _getFile() async {
    final FilePickerResult? file = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'xls'],
    );
    if (file != null && file.files.isNotEmpty) {
      final Uint8List bytes = file.files.first.bytes!;

      return Excel.decodeBytes(bytes);
    } else {
      return null;
    }
  }
}
