import 'package:flutter/material.dart';

import 'asset_db/asset_db.dart';
import 'theme.dart';
import 'views/editor/editor.dart';

Future<void> main() async {
  await initAssetDatabase();
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
