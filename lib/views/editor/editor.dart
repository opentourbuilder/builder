import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../utils/export.dart';
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

  Widget _currentPage = const Home();
  GlobalKey _currentPageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            onNewTourPressed: () async {
              var chosenPath = await FilePicker.platform.saveFile(
                dialogTitle: 'New Evresi Tour File',
                fileName: 'Untitled.evtour',
                type: FileType.custom,
                allowedExtensions: ["evtour"],
              );

              if (chosenPath != null) {
                setState(() => _currentPage = TourEditor(
                    key: _currentPageKey = GlobalKey(), path: chosenPath));
              }
            },
            onNewPoiSetPressed: () async {
              var chosenPath = await FilePicker.platform.saveFile(
                dialogTitle: 'New Evresi POI Set File',
                fileName: 'Untitled.evpoi',
                type: FileType.custom,
                allowedExtensions: ["evpoi"],
              );

              if (chosenPath != null) {
                setState(() => _currentPage =
                    Pois(key: _currentPageKey = GlobalKey(), path: chosenPath));
              }
            },
            onOpenPressed: () async {
              var chosenPath = (await FilePicker.platform.pickFiles(
                dialogTitle: 'Open Evresi File',
                type: FileType.custom,
                allowedExtensions: ["evtour", "evpoi"],
              ))
                  ?.files
                  .single
                  .path;

              if (chosenPath != null) {
                var ext = path.extension(chosenPath);

                if (ext == ".evtour") {
                  setState(() => _currentPage = TourEditor(
                      key: _currentPageKey = GlobalKey(), path: chosenPath));
                } else if (ext == ".evpoi") {
                  setState(() => _currentPage = Pois(
                      key: _currentPageKey = GlobalKey(), path: chosenPath));
                } else {
                  return;
                }
              }
            },
            showExportTour: _currentPage is TourEditor,
            onExportTourPressed: () async {
              var sourcePoiSets = (await FilePicker.platform.pickFiles(
                dialogTitle: 'Choose POI Sets for Tour Export',
                type: FileType.custom,
                allowedExtensions: ["evpoi"],
                allowMultiple: true,
              ))
                  ?.files
                  .map((e) => e.path!)
                  .toList();

              if (!mounted) return;

              Navigator.of(context).push(DialogRoute(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return const Center(
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                },
              ));

              export(
                db: (_currentPageKey.currentState as TourEditorState).db,
                sourcePoiSets: sourcePoiSets ?? [],
                promptForDestFile: () async {
                  var saveExport =
                      await Navigator.of(context).pushReplacement(DialogRoute(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Export finished.'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Don\'t save'),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          TextButton(
                            child: const Text('Save'),
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ],
                      );
                    },
                  ));

                  if (!saveExport) return null;

                  return await FilePicker.platform.saveFile(
                    dialogTitle: 'Save Export',
                    fileName: 'tour_export.zip',
                  );
                },
              );
            },
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _currentPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatefulWidget {
  const TopBar({
    super.key,
    required this.onNewTourPressed,
    required this.onNewPoiSetPressed,
    required this.onOpenPressed,
    required this.showExportTour,
    required this.onExportTourPressed,
  });

  final void Function() onNewTourPressed;
  final void Function() onNewPoiSetPressed;
  final void Function() onOpenPressed;
  final bool showExportTour;
  final void Function() onExportTourPressed;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  GlobalKey currentPageKey = GlobalKey();

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
            if (Platform.isMacOS) Expanded(child: MoveWindow()),
            _button(
              context,
              icon: Icons.note_add_outlined,
              text: "New Tour...",
              onPressed: widget.onNewTourPressed,
            ),
            _button(
              context,
              icon: Icons.note_add_outlined,
              text: "New POI Set...",
              onPressed: widget.onNewPoiSetPressed,
            ),
            _button(
              context,
              icon: Icons.file_open_outlined,
              text: "Open...",
              onPressed: widget.onOpenPressed,
            ),
            if (widget.showExportTour)
              _button(
                context,
                icon: Icons.upload_file_outlined,
                text: "Export Tour...",
                onPressed: widget.onExportTourPressed,
              ),
            if (!Platform.isMacOS) Expanded(child: MoveWindow()),
            if (!Platform.isMacOS) MinimizeWindowButton(colors: buttonColors),
            if (!Platform.isMacOS) MaximizeWindowButton(colors: buttonColors),
            if (!Platform.isMacOS) CloseWindowButton(colors: buttonColors),
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
