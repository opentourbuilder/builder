import 'package:flutter/material.dart';

import 'theme.dart';
import 'views/editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tour Builder',
      theme: themeData,
      home: EditorPage(),
    );
  }
}
