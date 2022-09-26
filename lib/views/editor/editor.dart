import 'dart:io';

import 'package:builder/db/export.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '/db/db.dart' as db;
import '/views/editor/pois/pois.dart';
import 'home.dart';
import 'tour/tour.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final GlobalKey<NavigatorState> navKey = GlobalKey();

  db.EvresiDatabaseType? dbType;

  @override
  void initState() {
    super.initState();

    db.instance.addOpenListener(_onDbOpen);
  }

  @override
  void dispose() {
    db.instance.removeOpenListener(_onDbOpen);

    super.dispose();
  }

  void _onDbOpen() {
    setState(() => dbType = db.instance.type);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox();
    if (dbType == null) {
      child = const Home();
    } else if (dbType == db.EvresiDatabaseType.tour) {
      child = const TourEditor();
    } else if (dbType == db.EvresiDatabaseType.poiSet) {
      child = const Pois();
    }

    return Scaffold(
      body: Column(
        children: [
          TopBar(
            onExportStart: () {
              Navigator.of(context).push(DialogRoute(
                context: context,
                builder: (context) {
                  return const Center(
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ));
            },
            onExportFinish: () {
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.onExportStart,
    required this.onExportFinish,
  });

  final void Function() onExportStart;
  final void Function() onExportFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          color: const Color.fromARGB(255, 233, 236, 255),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _button(
                icon: Icons.note_add,
                text: "New Tour...",
                onPressed: () async {
                  var chosenPath = await FilePicker.platform.saveFile(
                    dialogTitle: 'New Evresi Tour File',
                    fileName: 'Untitled.evtour',
                  );

                  if (chosenPath != null) {
                    await db.instance.close();

                    await db.instance
                        .open(chosenPath, db.EvresiDatabaseType.tour);
                  }
                },
              ),
              _button(
                icon: Icons.note_add,
                text: "New POI Set...",
                onPressed: () async {
                  var chosenPath = await FilePicker.platform.saveFile(
                    dialogTitle: 'New Evresi POI Set File',
                    fileName: 'Untitled.evpoi',
                  );

                  if (chosenPath != null) {
                    await db.instance.close();

                    await db.instance
                        .open(chosenPath, db.EvresiDatabaseType.poiSet);
                  }
                },
              ),
              _button(
                icon: Icons.file_open,
                text: "Open...",
                onPressed: () async {
                  var chosenPath = (await FilePicker.platform.pickFiles(
                    dialogTitle: 'Open Evresi File',
                    allowedExtensions: ["evtour", "evpoi"],
                  ))
                      ?.files
                      .single
                      .path;

                  if (chosenPath != null) {
                    await db.instance.close();

                    var ext = path.extension(chosenPath);

                    if (ext == ".evtour") {
                      await db.instance
                          .open(chosenPath, db.EvresiDatabaseType.tour);
                    } else if (ext == ".evpoi") {
                      await db.instance
                          .open(chosenPath, db.EvresiDatabaseType.poiSet);
                    } else {
                      return;
                    }
                  }
                },
              ),
              _button(
                icon: Icons.upload_file,
                text: "Export...",
                onPressed: () async {
                  var chosenFiles = (await FilePicker.platform.pickFiles(
                    dialogTitle: 'Choose Evresi Files to Export',
                    allowedExtensions: ["evtour", "evpoi"],
                    allowMultiple: true,
                  ))
                      ?.files;

                  if (chosenFiles != null) {
                    onExportStart();
                    var jsonString = await exportToJson(
                        <String>[...chosenFiles.map((e) => e.path!)]);

                    var chosenPath = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save Export',
                      fileName: 'export.json',
                    );

                    if (chosenPath != null) {
                      await File(chosenPath).writeAsString(jsonString);
                    }
                    onExportFinish();
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(
          height: 2,
          thickness: 2,
          color: Color.fromARGB(255, 196, 202, 234),
        )
      ],
    );
  }

  Widget _button({
    required IconData icon,
    required String text,
    required void Function() onPressed,
  }) {
    return RawMaterialButton(
      onPressed: onPressed,
      splashColor: const Color.fromARGB(0, 0, 0, 0),
      highlightColor: const Color.fromARGB(20, 0, 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 82, 87, 115)),
          const SizedBox(width: 8.0),
          Text(
            text,
            style: const TextStyle(
              color: Color.fromARGB(255, 82, 87, 115),
            ),
          ),
        ],
      ),
    );
  }
}
