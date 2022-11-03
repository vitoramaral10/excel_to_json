library excel_to_json;

import 'dart:convert';
import 'dart:developer';

import 'package:excel_facility/excel_facility.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// This is the main project class.
class ExcelToJson {
  /// Use this method to convert the file to a json.
  Future<String?> convert() async {
    Excel? excel = await _getFile();

    if (excel != null) {
      List<String> tables = _getTables(excel);

      int i = 0;
      Map<String, dynamic> json = {};

      for (String table in tables) {
        List<Data?> keys = [];
        json.addAll({table: []});

        for (List<Data?> row in excel.tables[table]?.rows ?? []) {
          try {
            if (i == 0) {
              keys = row;
              i++;
            } else {
              Map<String, dynamic> temp = _getRows(keys, row);

              json[table].add(temp);
            }
          } catch (ex) {
            log(ex.toString());

            rethrow;
          }
        }
        i = 0;
      }

      return jsonEncode(json);
    }

    return null;
  }

  Map<String, dynamic> _getRows(List<Data?> keys, List<Data?> row) {
    Map<String, dynamic> temp = {};
    int j = 0;
    String tk = '';

    for (Data? key in keys) {
      if (key != null && key.value != null) {
        tk = key.value.toString();

        if ([
          CellType.String,
          CellType.int,
          CellType.double,
          CellType.bool,
        ].contains(row[j]?.cellType)) {
          if (row[j]?.value == 'true') {
            temp[tk] = true;
          } else if (row[j]?.value == 'false') {
            temp[tk] = false;
          } else {
            temp[tk] = row[j]?.value;
          }
        } else if (row[j]?.cellType == CellType.Formula) {
          temp[tk] = row[j]?.value.toString();
        }

        j++;
      }
    }

    return temp;
  }

  List<String> _getTables(Excel excel) {
    List<String> keys = [];

    for (String table in excel.tables.keys) {
      keys.add(table);
    }

    return keys;
  }

  Future<Excel?> _getFile() async {
    FilePickerResult? file = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'xls'],
    );
    if (file != null && file.files.isNotEmpty) {
      Uint8List bytes = file.files.first.bytes!;

      return Excel.decodeBytes(bytes);
    } else {
      return null;
    }
  }
}
