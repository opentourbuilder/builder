import 'dart:async';

import 'package:flutter/material.dart';

import '/db/db.dart' as db;
import '/db/models/poi.dart';
import '/views/editor/pois/map.dart';
import '/widgets/gallery_editor/gallery_editor.dart';
import '/widgets/location_field.dart';
import '/widgets/modal.dart';

class Pois extends StatefulWidget {
  const Pois({
    super.key,
  });

  @override
  State<Pois> createState() => _PoisState();
}

class _PoisState extends State<Pois> {
  final _contentEditorKey = GlobalKey();
  final _mapKey = GlobalKey();

  db.Uuid? selectedPoi;

  StreamSubscription<db.Event>? _eventsSubscription;

  List<db.PointSummary> _pois = [];

  @override
  void initState() {
    super.initState();
    _eventsSubscription = db.instance.events.listen(_onEvent);
    db.instance.requestEvent(const db.PoisEventDescriptor());
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  void _onEvent(db.Event event) {
    if (event.desc == const db.PoisEventDescriptor()) {
      setState(() {
        _pois = event.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final contentEditor = Container(
        key: _contentEditorKey,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Stack(
          children: [
            _PoiList(
              selectPoi: (id) => setState(() => selectedPoi = id),
              pois: _pois,
            ),
            _PoiEditor(
              selectedPoi: selectedPoi,
              selectPoi: (id) => setState(() => selectedPoi = id),
            ),
          ],
        ),
      );

      final map = PoiMap(
        key: _mapKey,
        pois: _pois,
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

      return child;
    });
  }
}

class _PoiList extends StatefulWidget {
  const _PoiList({
    Key? key,
    required this.selectPoi,
    required this.pois,
  }) : super(key: key);

  final void Function(db.Uuid?) selectPoi;
  final List<db.PointSummary> pois;

  @override
  State<_PoiList> createState() => _PoiListState();
}

class _PoiListState extends State<_PoiList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: widget.pois.length + 1,
      itemBuilder: (context, index) {
        if (index < widget.pois.length) {
          return _Poi(
            key: ValueKey(widget.pois[index].id),
            onTap: () => widget.selectPoi(widget.pois[index].id),
            summary: widget.pois[index],
          );
        } else {
          return UnconstrainedBox(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: () async {
                  var poi = await db.instance.createPoi(
                    Poi(
                      name: "Untitled",
                      desc: "",
                      lat: 0,
                      lng: 0,
                    ),
                  );
                  poi.dispose();
                },
                child: Row(
                  children: const [
                    Icon(Icons.add),
                    SizedBox(width: 16.0),
                    Text("Create Point of Interest"),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _Poi extends StatefulWidget {
  const _Poi({
    Key? key,
    required this.summary,
    required this.onTap,
  }) : super(key: key);

  final db.PointSummary summary;
  final void Function() onTap;

  @override
  State<_Poi> createState() => _PoiState();
}

class _PoiState extends State<_Poi> {
  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.summary.id),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16.0),
              Text(
                widget.summary.name!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Expanded(child: Container()),
              RawMaterialButton(
                focusColor: const Color(0x10000088),
                highlightColor: const Color(0x08000088),
                hoverColor: const Color(0x08000088),
                splashColor: const Color(0x08000088),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                onPressed: () {},
                child: const Icon(Icons.location_pin),
              ),
              RawMaterialButton(
                focusColor: const Color(0x10000088),
                highlightColor: const Color(0x08000088),
                hoverColor: const Color(0x08000088),
                splashColor: const Color(0x08000088),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                onPressed: () {
                  db.instance.deletePoi(widget.summary.id);
                },
                child: const Icon(Icons.delete),
              ),
              RawMaterialButton(
                focusColor: const Color(0x10000088),
                highlightColor: const Color(0x08000088),
                hoverColor: const Color(0x08000088),
                splashColor: const Color(0x08000088),
                constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                onPressed: () {
                  widget.onTap();
                },
                child: const Icon(Icons.edit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _poiEditorInputDecoration = InputDecoration(
  filled: true,
  fillColor: Color(0xFFFFFFFF),
  hoverColor: Color(0xFFFFFFFF),
);

class _PoiEditor extends StatefulWidget {
  const _PoiEditor({
    super.key,
    required this.selectedPoi,
    required this.selectPoi,
  });

  final db.Uuid? selectedPoi;
  final void Function(db.Uuid?) selectPoi;

  @override
  State<StatefulWidget> createState() => _PoiEditorState();
}

class _PoiEditorState extends State<_PoiEditor> {
  db.Uuid? poiId;
  DbPoi? poi;

  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();

  @override
  void dispose() {
    poi?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PoiEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedPoi != poiId) {
      poiId = widget.selectedPoi;

      poi?.dispose();
      poi = null;
      if (poiId != null) {
        db.instance.poi(poiId!).then((value) {
          value?.listen((() => setState(() {})));
          setState(() => poi = value);
          titleController.text = poi?.data?.name ?? "";
          descController.text = poi?.data?.desc ?? "";
        });
      }
    }

    return AnimatedScale(
      scale: widget.selectedPoi != null ? 1.0 : 0.0,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: widget.selectedPoi == null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Modal(
            title: const Text("Edit Point of Interest"),
            child: Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: _poiEditorInputDecoration.copyWith(
                          labelText: "Title"),
                      controller: titleController,
                      onChanged: (name) {
                        poi!.data!.name = name;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      decoration: _poiEditorInputDecoration.copyWith(
                          labelText: "Description"),
                      minLines: 4,
                      maxLines: 4,
                      controller: descController,
                      onChanged: (desc) {
                        poi!.data!.desc = desc;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    LocationField(
                      point: poi,
                    ),
                    const SizedBox(height: 16.0),
                    if (widget.selectedPoi != null)
                      GalleryEditor(itemId: widget.selectedPoi!),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      child: UnconstrainedBox(
                        child: Row(
                          children: const [
                            Icon(Icons.check),
                            SizedBox(width: 16.0),
                            Text("Done"),
                          ],
                        ),
                      ),
                      onPressed: () => widget.selectPoi(null),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
