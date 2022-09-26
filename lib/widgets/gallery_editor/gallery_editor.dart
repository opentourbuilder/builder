import 'dart:io';

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

    db.instance
        .gallery(widget.itemId)
        .then((value) => setState(() => gallery = value));
  }

  @override
  void didUpdateWidget(covariant GalleryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    db.instance
        .gallery(widget.itemId)
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
    return SizedBox(
      height: 64,
      child: Scrollbar(
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < itemCount - 1) {
              return Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () async {
                    var result = await Navigator.of(context,
                            rootNavigator: true)
                        .push(GalleryImageModalRoute(gallery!.data![index]));

                    if (result is GalleryImageModalResultUpdated) {
                      setState(() => gallery!.data![index] = result.asset.name);
                    } else if (result is GalleryImageModalResultDeleted) {
                      setState(() => gallery!.data!.remove(index));
                    }
                  },
                  child: gallery != null
                      ? FutureBuilder(
                          future: assetDbInstance.asset(gallery!.data![index]),
                          builder: (context, snapshot) {
                            if (snapshot.data != null) {
                              return Image.file(
                                File((snapshot.data! as Asset).fullPath),
                                fit: BoxFit.cover,
                              );
                            } else {
                              return const SizedBox();
                            }
                          },
                        )
                      : null,
                ),
              );
            } else {
              return UnconstrainedBox(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Tooltip(
                    message: "Add an image to the gallery",
                    child: IconButton(
                      onPressed: () async {
                        var result =
                            await Navigator.of(context, rootNavigator: true)
                                .push(GalleryImageModalRoute(null));

                        if (result is GalleryImageModalResultUpdated) {
                          setState(() => gallery!.data!.add(result.asset.name));
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
