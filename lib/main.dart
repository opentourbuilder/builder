import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'asset_db/asset_db.dart';
import 'theme.dart';
import 'views/editor/editor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAssetDatabase();
  sqfliteFfiInit();
  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
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
