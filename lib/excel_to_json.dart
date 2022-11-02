library excel_to_json;

import 'dart:convert';
import 'dart:developer';

import 'package:excel_facility/excel_facility.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ExcelToJson {
  Future<String?> convert() async {
    FilePickerResult? file = await FilePicker.platform.pickFiles(
      withData: true,
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
                if (key != null && key.value != null) {
                  tk = key.value.toString();
                  if ((row[j].runtimeType == String)) {
                    temp[tk] = "\u201C${row[j].value}\u201D";
                  } else {
                    if (row[j] != null) {
                      temp[tk] = row[j].value.toString();
                    } else {
                      temp[tk] = '';
                    }
                  }
                  j++;
                }
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
