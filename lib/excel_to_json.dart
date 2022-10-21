library excel_to_json;

import 'dart:convert';
import 'dart:developer';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ExcelToJson {
  Future<String?> convert() async {
    FilePickerResult? file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'xls'],
    );
    if (file != null && file.files.isNotEmpty) {
      Uint8List bytes = file.files.first.bytes!;
      Excel excel = Excel.decodeBytes(bytes);

      int i = 0;
      List keys = [];
      List<Map<String, dynamic>> json = [];

      for (String table in excel.tables.keys) {
        for (var row in excel.tables[table]?.rows ?? []) {
          try {
            if (i == 0) {
              keys = row;
              i++;
            } else {
              Map<String, dynamic> temp = {};
              int j = 0;
              String tk = '';

              for (var key in keys) {
                tk = key.value;
                temp[tk] = (row[j].runtimeType == String)
                    ? "\u201C${row[j].value}\u201D"
                    : row[j].value;
                j++;
              }
              json.add(temp);
            }
          } catch (ex) {
            log(ex.toString());

            rethrow;
          }
        }
      }

      return jsonEncode(json);
    }

    return null;
  }
}
