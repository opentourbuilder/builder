import 'dart:io';

import 'package:builder/asset_db/asset_db.dart';
import 'package:builder/widgets/modal.dart';
import 'package:flutter/material.dart';

class AssetManagerScreen extends StatefulWidget {
  const AssetManagerScreen({super.key});

  @override
  State<AssetManagerScreen> createState() => _AssetManagerScreenState();
}

class _AssetManagerScreenState extends State<AssetManagerScreen> {
  Future<List<Asset>> assets = assetDbInstance.list();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Asset>>(
      future: assets,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var currentAssets = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150.0,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
              ),
              itemCount: currentAssets.length,
              itemBuilder: (context, index) {
                return Material(
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  type: MaterialType.card,
                  elevation: 5,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                    onTap: () async {
                      await Navigator.of(context)
                          .push(AssetManagerModalRoute(currentAssets[index]));

                      setState(() {
                        assets = assetDbInstance.list();
                      });
                    },
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16.0)),
                            color: Color.fromARGB(255, 24, 24, 24),
                          ),
                        ),
                        if (currentAssets[index].type == AssetType.image)
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(16.0)),
                            child: Image.file(
                              File(currentAssets[index].localPath),
                              fit: BoxFit.cover,
                              opacity: AlwaysStoppedAnimation(0.55),
                            ),
                          ),
                        if (currentAssets[index].type == AssetType.narration)
                          const Icon(
                            Icons.mic,
                            size: 64,
                            color: Colors.white38,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            currentAssets[index].name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else if (snapshot.hasError) {
          return const Text("Error");
        } else {
          return const CircularProgressIndicator.adaptive();
        }
      },
    );
  }
}

class AssetManagerModalRoute extends ModalRoute<void> {
  AssetManagerModalRoute(this.asset);

  final Asset asset;

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
    return AssetManagerModal(asset: asset);
  }
}

class AssetManagerModal extends StatefulWidget {
  const AssetManagerModal({super.key, required this.asset});

  final Asset asset;

  @override
  State<AssetManagerModal> createState() => _AssetManagerModalState();
}

class _AssetManagerModalState extends State<AssetManagerModal> {
  String? _attribution;
  String? _alt;

  @override
  void initState() {
    super.initState();

    widget.asset.attribution
        .then((value) => setState(() => _attribution = value));
    widget.asset.alt.then((value) => setState(() => _alt = value));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Modal(
          title: Text("Editing Asset: ${widget.asset.name}"),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.asset.type == AssetType.image)
                  TextField(
                    decoration: const InputDecoration(labelText: "Alt Text"),
                    minLines: 2,
                    maxLines: 2,
                    controller: TextEditingController(text: _alt ?? ""),
                    onChanged: (desc) {
                      if (desc.trim().isNotEmpty) {
                        _alt = desc;
                      } else {
                        _alt = null;
                      }
                      widget.asset.setAlt(_alt);
                    },
                  ),
                if (widget.asset.type == AssetType.image)
                  const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: "Attribution"),
                  minLines: 2,
                  maxLines: 2,
                  controller: TextEditingController(text: _attribution ?? ""),
                  onChanged: (desc) {
                    if (desc.trim().isNotEmpty) {
                      _attribution = desc;
                    } else {
                      _attribution = null;
                    }
                    widget.asset.setAttribution(_attribution);
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.asset.delete();
                    Navigator.of(context).pop();
                  },
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Colors.red),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.delete),
                      SizedBox(width: 8.0),
                      Text("Delete Permanently"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
