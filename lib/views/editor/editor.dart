import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '/db/db.dart' as db;
import '../../utils/export.dart';
import '/views/editor/export.dart';
import '/views/editor/pois/pois.dart';
import 'home.dart';
import 'tour/tour.dart';

enum _CurrentPage {
  home,
  tour,
  poiSet,
  exporting,
  finishedExport,
}

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final GlobalKey<NavigatorState> navKey = GlobalKey();

  _CurrentPage _currentPage = _CurrentPage.home;

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
    setState(() {
      if (db.instance.type == null) {
        _currentPage = _CurrentPage.home;
      } else if (db.instance.type == db.EvresiDatabaseType.tour) {
        _currentPage = _CurrentPage.tour;
      } else if (db.instance.type == db.EvresiDatabaseType.poiSet) {
        _currentPage = _CurrentPage.poiSet;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox();
    if (_currentPage == _CurrentPage.home) {
      child = const Home();
    } else if (_currentPage == _CurrentPage.tour) {
      child = const TourEditor();
    } else if (_currentPage == _CurrentPage.poiSet) {
      child = const Pois();
    } else if (_currentPage == _CurrentPage.exporting) {
      child = const ExportPage(finished: false);
    } else if (_currentPage == _CurrentPage.finishedExport) {
      child = const ExportPage(finished: true);
    }

    return Scaffold(
      body: Column(
        children: [
          TopBar(
            onExportStart: () {
              setState(() => _currentPage = _CurrentPage.exporting);
            },
            onExportFinish: () {
              setState(() => _currentPage = _CurrentPage.finishedExport);
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
    final WindowButtonColors buttonColors = WindowButtonColors(
      normal: Colors.transparent,
      mouseOver: const Color.fromARGB(48, 0, 0, 0),
      mouseDown: const Color.fromARGB(96, 0, 0, 0),
      iconNormal: const Color.fromARGB(255, 237, 239, 255),
      iconMouseOver: const Color.fromARGB(255, 237, 239, 255),
      iconMouseDown: const Color.fromARGB(255, 237, 239, 255),
    );

    return WindowTitleBarBox(
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _button(
              context,
              icon: Icons.note_add_outlined,
              text: "New Tour...",
              onPressed: () async {
                var chosenPath = await FilePicker.platform.saveFile(
                  dialogTitle: 'New Evresi Tour File',
                  fileName: 'Untitled.evtour',
                  type: FileType.custom,
                  allowedExtensions: ["evtour"],
                );

                if (chosenPath != null) {
                  await db.instance.close();

                  await db.instance
                      .open(chosenPath, db.EvresiDatabaseType.tour);
                }
              },
            ),
            _button(
              context,
              icon: Icons.note_add_outlined,
              text: "New POI Set...",
              onPressed: () async {
                var chosenPath = await FilePicker.platform.saveFile(
                  dialogTitle: 'New Evresi POI Set File',
                  fileName: 'Untitled.evpoi',
                  type: FileType.custom,
                  allowedExtensions: ["evpoi"],
                );

                if (chosenPath != null) {
                  await db.instance.close();

                  await db.instance
                      .open(chosenPath, db.EvresiDatabaseType.poiSet);
                }
              },
            ),
            _button(
              context,
              icon: Icons.file_open_outlined,
              text: "Open...",
              onPressed: () async {
                var chosenPath = (await FilePicker.platform.pickFiles(
                  dialogTitle: 'Open Evresi File',
                  type: FileType.custom,
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
              context,
              icon: Icons.upload_file_outlined,
              text: "Export...",
              onPressed: () {
                onExportStart();
                export(
                  onFinish: onExportFinish,
                  promptForSourceFiles: () async {
                    return (await FilePicker.platform.pickFiles(
                      dialogTitle: 'Choose Evresi Files to Export',
                      type: FileType.custom,
                      allowedExtensions: ["evtour", "evpoi"],
                      allowMultiple: true,
                    ))
                        ?.files
                        .map((e) => e.path!)
                        .toList();
                  },
                  promptForDestFile: () async {
                    return await FilePicker.platform.saveFile(
                      dialogTitle: 'Save Export',
                      fileName: 'export.json',
                    );
                  },
                );
              },
            ),
            Expanded(
              child: MoveWindow(
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    MinimizeWindowButton(colors: buttonColors),
                    MaximizeWindowButton(colors: buttonColors),
                    CloseWindowButton(colors: buttonColors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context, {
    required IconData icon,
    required String text,
    required void Function() onPressed,
  }) {
    const color = Color.fromARGB(255, 237, 239, 255);

    return RawMaterialButton(
      onPressed: onPressed,
      splashColor: const Color.fromARGB(0, 0, 0, 0),
      hoverColor: const Color.fromARGB(48, 0, 0, 0),
      highlightColor: const Color.fromARGB(48, 0, 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: Theme.of(context).textTheme.button!.copyWith(
                  color: color,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}
