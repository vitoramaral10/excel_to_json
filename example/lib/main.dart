import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(const ExcelToJsonApp());
}

class ExcelToJsonApp extends StatefulWidget {
  const ExcelToJsonApp({Key? key}) : super(key: key);

  @override
  State<ExcelToJsonApp> createState() => _ExcelToJsonAppState();
}

class _ExcelToJsonAppState extends State<ExcelToJsonApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excel to JSON Converter',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Home(onToggleTheme: _toggleTheme),
    );
  }
}
