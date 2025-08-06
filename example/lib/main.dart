import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(const ExcelToJsonApp());
}

class ExcelToJsonApp extends StatelessWidget {
  const ExcelToJsonApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excel to JSON Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
