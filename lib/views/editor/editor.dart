import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '/db/db.dart' as db;
import '/db/export.dart';
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
      body: WindowBorder(
        color: const Color.fromARGB(255, 168, 174, 207),
        width: 1,
        child: Column(
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
        WindowTitleBarBox(
          child: MoveWindow(
            child: Container(
              color: const Color.fromARGB(255, 233, 236, 255),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _button(
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
                    icon: Icons.upload_file_outlined,
                    text: "Export...",
                    onPressed: () async {
                      var chosenFiles = (await FilePicker.platform.pickFiles(
                        dialogTitle: 'Choose Evresi Files to Export',
                        type: FileType.custom,
                        allowedExtensions: ["evtour", "evpoi"],
                        allowMultiple: true,
                      ))
                          ?.files;

                      if (chosenFiles != null) {
                        onExportStart();
                        var jsonString = await exportToJson(
                            <String>[...chosenFiles.map((e) => e.path!)]);
                        onExportFinish();

                        var chosenPath = await FilePicker.platform.saveFile(
                          dialogTitle: 'Save Export',
                          fileName: 'export.json',
                        );

                        if (chosenPath != null) {
                          await File(chosenPath).writeAsString(jsonString);
                        }
                      }
                    },
                  ),
                  const Expanded(child: SizedBox()),
                  MinimizeWindowButton(),
                  MaximizeWindowButton(),
                  CloseWindowButton(),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color.fromARGB(255, 168, 174, 207),
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
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color.fromARGB(255, 82, 87, 115),
            size: 20,
          ),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: const TextStyle(
              color: Color.fromARGB(255, 82, 87, 115),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
