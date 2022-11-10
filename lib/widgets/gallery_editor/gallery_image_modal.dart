import 'dart:io';

import '/widgets/asset_picker.dart';
import 'package:flutter/material.dart';

import '/asset_db/asset_db.dart';
import '../modal.dart';

abstract class GalleryImageModalResult {
  const GalleryImageModalResult();
}

class GalleryImageModalResultUpdated extends GalleryImageModalResult {
  const GalleryImageModalResultUpdated(this.asset);

  final Asset asset;
}

class GalleryImageModalResultDeleted extends GalleryImageModalResult {
  const GalleryImageModalResultDeleted();
}

class GalleryImageModalResultEmpty extends GalleryImageModalResult {
  const GalleryImageModalResultEmpty();
}

class GalleryImageModalRoute extends ModalRoute<GalleryImageModalResult> {
  GalleryImageModalRoute(this.currentAsset);

  final String? currentAsset;

  @override
  Color? get barrierColor => const Color.fromARGB(64, 0, 0, 0);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return GalleryImageModal(currentAsset: currentAsset);
  }
}

class GalleryImageModal extends StatefulWidget {
  const GalleryImageModal({super.key, required this.currentAsset});

  final String? currentAsset;

  @override
  State<GalleryImageModal> createState() => _GalleryImageModalState();
}

class _GalleryImageModalState extends State<GalleryImageModal> {
  Asset? selectedAsset;

  @override
  void initState() {
    super.initState();

    if (widget.currentAsset != null) {
      assetDbInstance
          .asset(widget.currentAsset!)
          .then((currentAsset) => setState(() => selectedAsset = currentAsset));
    }
  }

  @override
  Widget build(BuildContext context) {
    var selectedAssetFile =
        selectedAsset != null ? File(selectedAsset!.localPath) : null;

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Center(
        child: SizedBox(
          width: 400,
          child: Modal(
            title: const Text("Gallery Image"),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedAssetFile != null)
                    Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromARGB(40, 0, 0, 0),
                              blurRadius: 5,
                              blurStyle: BlurStyle.normal,
                            ),
                          ],
                        ),
                        child: Image.file(
                          selectedAssetFile,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  if (selectedAssetFile != null) const SizedBox(height: 16.0),
                  AssetPicker(
                    type: AssetType.image,
                    selectedAssetName: widget.currentAsset,
                    onAssetSelected: (asset) {
                      setState(() {
                        selectedAsset = asset;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (selectedAsset != null) {
                            Navigator.of(context, rootNavigator: true).pop(
                                GalleryImageModalResultUpdated(selectedAsset!));
                          }
                        },
                        style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.green),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check),
                            SizedBox(width: 16.0),
                            Text("Save"),
                          ],
                        ),
                      ),
                      if (widget.currentAsset != null)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .pop(const GalleryImageModalResultDeleted());
                          },
                          style: const ButtonStyle(
                            backgroundColor:
                                MaterialStatePropertyAll(Colors.red),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.delete),
                              SizedBox(width: 16.0),
                              Text("Delete"),
                            ],
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true)
                              .pop(const GalleryImageModalResultEmpty());
                        },
                        style: const ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(
                              Color.fromARGB(255, 96, 96, 96)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.close),
                            SizedBox(width: 16.0),
                            Text("Cancel"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
