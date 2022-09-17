import 'package:flutter/material.dart';

import 'db/db.dart';
import 'theme.dart';
import 'views/editor.dart';

Future<void> main() async {
  await initEvresiDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tour Builder',
      theme: themeData,
      home: const EditorPage(),
    );
  }
}
