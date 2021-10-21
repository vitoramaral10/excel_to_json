import 'package:excel_to_json/ExcelToJson.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.amber,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  child: Text("PRESS TO UPLOAD EXCEL AND CONVERT TO JSON"),
                  onPressed: () {
                    ExcelToJson().convert().then((onValue) {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
