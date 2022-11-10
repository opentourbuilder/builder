import 'dart:io';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '/asset_db/asset_db.dart';
import '/db/db.dart' as db;
import '/db/models/gallery.dart';
import '/widgets/gallery_editor/gallery_image_modal.dart';

class GalleryEditor extends StatefulWidget {
  const GalleryEditor({
    super.key,
    required this.itemId,
  });

  final db.Uuid itemId;

  @override
  State<GalleryEditor> createState() => _GalleryEditorState();
}

class _GalleryEditorState extends State<GalleryEditor> {
  final ScrollController scrollController = ScrollController();

  DbGallery? gallery;

  @override
  void initState() {
    super.initState();

    context
        .read<Future<db.EvresiDatabase>>()
        .then((db) => db.gallery(widget.itemId))
        .then((value) => setState(() => gallery = value));
  }

  @override
  void didUpdateWidget(covariant GalleryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    context
        .read<Future<db.EvresiDatabase>>()
        .then((db) => db.gallery(widget.itemId))
        .then((value) => setState(() => gallery = value));
  }

  @override
  void dispose() {
    gallery?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var itemCount = gallery != null ? gallery!.data!.length + 1 : 0;
    return Container(
      height: 80,
      decoration: const ShapeDecoration(
        shape: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(3.0)),
        ),
        color: Colors.white,
      ),
      child: Scrollbar(
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            if (index < itemCount - 1) {
              return _GalleryEditorSmallImage(
                assetName: gallery?.data?[index],
                update: (newAssetName) {
                  setState(() => gallery?.data?[index] = newAssetName);
                },
                remove: () {
                  setState(() => gallery?.data?.remove(index));
                },
              );
            } else {
              return UnconstrainedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Tooltip(
                    message: "Add an image to the gallery",
                    child: IconButton(
                      onPressed: () async {
                        var result =
                            await Navigator.of(context, rootNavigator: true)
                                .push(GalleryImageModalRoute(null));

                        if (result is GalleryImageModalResultUpdated) {
                          setState(() {
                            gallery!.data!.add(result.asset.name);
                          });
                        }
                      },
                      iconSize: 28.0,
                      icon: const Icon(
                        Icons.add,
                        size: 28.0,
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _GalleryEditorSmallImage extends StatefulWidget {
  const _GalleryEditorSmallImage({
    required this.assetName,
    required this.update,
    required this.remove,
  });

  final String? assetName;
  final void Function(String) update;
  final void Function() remove;

  @override
  State<_GalleryEditorSmallImage> createState() =>
      _GalleryEditorSmallImageState();
}

class _GalleryEditorSmallImageState extends State<_GalleryEditorSmallImage> {
  late Future<Asset?> asset;

  @override
  void initState() {
    super.initState();

    if (widget.assetName != null) {
      asset = assetDbInstance.asset(widget.assetName!);
    } else {
      asset = Future.value(null);
    }
  }

  @override
  void didUpdateWidget(covariant _GalleryEditorSmallImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.assetName != oldWidget.assetName) {
      if (widget.assetName != null) {
        asset = assetDbInstance.asset(widget.assetName!);
      } else {
        asset = Future.value(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(right: 8.0),
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(40, 0, 0, 0),
            blurRadius: 2,
            spreadRadius: 1,
            blurStyle: BlurStyle.normal,
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          var result = await Navigator.of(context, rootNavigator: true)
              .push(GalleryImageModalRoute(widget.assetName));

          if (result is GalleryImageModalResultUpdated) {
            setState(() => widget.update(result.asset.name));
          } else if (result is GalleryImageModalResultDeleted) {
            setState(() => widget.remove());
          }
        },
        child: FutureBuilder(
          future: asset,
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return Image.file(
                File((snapshot.data! as Asset).localPath),
                fit: BoxFit.cover,
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
