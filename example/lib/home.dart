import 'package:excel_to_json/excel_to_json.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Converter Excel em JSON')),
      body: Center(
        child: ElevatedButton(
          child: const Text("PRESS TO UPLOAD EXCEL AND CONVERT TO JSON"),
          onPressed: () async {
            String? excel = await ExcelToJson().convert();
            if (kDebugMode) {
              print(excel);
            }
          },
        ),
      ),
    );
  }
}
