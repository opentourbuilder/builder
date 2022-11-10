import 'dart:io';

import 'package:builder/asset_db/asset_db.dart';
import 'package:flutter/material.dart';

class AssetManagerScreen extends StatefulWidget {
  const AssetManagerScreen({super.key});

  @override
  State<AssetManagerScreen> createState() => _AssetManagerScreenState();
}

class _AssetManagerScreenState extends State<AssetManagerScreen> {
  final Future<List<Asset>> assets = assetDbInstance.list();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Asset>>(
      future: assets,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var assets = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150.0,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
              ),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                return Material(
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  type: MaterialType.card,
                  elevation: 5,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                    onTap: () {},
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        if (assets[index].type == AssetType.image)
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(16.0)),
                            child: Image.file(
                              File(assets[index].fullPath),
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.15),
                            ),
                          ),
                        if (assets[index].type == AssetType.narration)
                          const Icon(
                            Icons.mic,
                            size: 64,
                            color: Colors.black26,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            assets[index].name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
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
