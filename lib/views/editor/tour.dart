import 'dart:async';

import 'package:builder/db/models/tour.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/db/db.dart' as db;
import '/models/editor/tour.dart';
import 'tour/map.dart';
import 'tour/waypoints.dart';

class TourEditor extends StatefulWidget {
  const TourEditor({Key? key, required this.tourId}) : super(key: key);

  final db.Uuid tourId;

  @override
  State<TourEditor> createState() => _TourEditorState();
}

class _TourEditorState extends State<TourEditor> {
  final _contentEditorKey = GlobalKey();
  final _mapKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final contentEditor = _TourContentEditor(
        key: _contentEditorKey,
        tourId: widget.tourId,
      );

      final map = TourMap(
        key: _mapKey,
        tourId: widget.tourId,
      );

      Widget child;
      if (constraints.maxWidth >= 800) {
        child = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            contentEditor,
            const VerticalDivider(
              width: 1.0,
              thickness: 1.0,
            ),
            Expanded(child: map),
          ],
        );
      } else {
        child = DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: Colors.black,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(child: Text("Content")),
                  Tab(child: Text("Map")),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    contentEditor,
                    map,
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return ChangeNotifierProvider(
        create: (_) => TourEditorModel(tourId: widget.tourId),
        child: child,
      );
    });
  }
}

class _TourContentEditor extends StatefulWidget {
  const _TourContentEditor({
    Key? key,
    required this.tourId,
  }) : super(key: key);

  final db.Uuid tourId;

  @override
  State<_TourContentEditor> createState() => _TourContentEditorState();
}

class _TourContentEditorState extends State<_TourContentEditor> {
  bool _tourLoaded = false;
  DbTour? _tour;

  @override
  void initState() {
    super.initState();
    db.instance.tour(widget.tourId).then((tour) {
      tour?.listen((() {
        setState(() {});
      }));
      setState(() {
        _tour = tour;
        _tourLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _tour?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tourLoaded && _tour == null) {
      // TODO: show error popup
      throw Exception("Error: loaded tour is null");
    }

    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelAlignment: FloatingLabelAlignment.start,
      isDense: true,
    );

    return DefaultTabController(
      length: 2,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    enabled: _tour != null,
                    controller: _tour != null
                        ? TextEditingController(text: _tour!.name)
                        : null,
                    onChanged: _tour != null
                        ? (value) {
                            _tour?.name = value;
                          }
                        : null,
                    decoration: inputDecoration.copyWith(labelText: "Title"),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    minLines: 8,
                    maxLines: 8,
                    enabled: _tour != null,
                    controller: _tour != null
                        ? TextEditingController(text: _tour!.desc)
                        : null,
                    onChanged: _tour != null
                        ? (value) {
                            _tour?.desc = value;
                          }
                        : null,
                    decoration:
                        inputDecoration.copyWith(labelText: "Description"),
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: Colors.black,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(child: Text("Route")),
                Tab(child: Text("POIs")),
              ],
            ),
            Expanded(
              child: TabBarView(children: [
                Waypoints(
                  tourId: widget.tourId,
                ),
                const Text("This is where the POI editor goes."),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
