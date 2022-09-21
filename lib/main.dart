import 'package:flutter/material.dart';

import 'asset_db/asset_db.dart' as asset_db;
import 'db/db.dart' as db;
import 'theme.dart';
import 'views/editor.dart';

Future<void> main() async {
  await asset_db.initAssetDatabase();
  await db.initEvresiDatabase();
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
