import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '/asset_db/asset_db.dart';

class AssetPicker extends StatefulWidget {
  const AssetPicker({
    super.key,
    this.selectedAssetName,
    required this.onAssetSelected,
    this.type,
  });

  final String? selectedAssetName;
  final void Function(Asset) onAssetSelected;
  final AssetType? type;

  @override
  State<AssetPicker> createState() => _AssetPickerState();
}

class _AssetPickerState extends State<AssetPicker> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController controller = TextEditingController();

  String? newAssetPath;
  String? newAssetName;
  String? newAssetError;

  @override
  void initState() {
    super.initState();

    if (widget.selectedAssetName != null) {
      controller.text = widget.selectedAssetName!;
    }
  }

  @override
  void didUpdateWidget(covariant AssetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    controller.text = widget.selectedAssetName ?? "";
  }

  @override
  Widget build(BuildContext context) {
    if (newAssetPath == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return RawAutocomplete<Asset>(
                textEditingController: controller,
                focusNode: focusNode,
                displayStringForOption: (asset) => asset.name,
                optionsViewBuilder: (context, onSelected, options) =>
                    _autocompleteOptionsBuilder(
                        context, onSelected, options, constraints.maxWidth),
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  return TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                      hoverColor: const Color(0xFFFFFFFF),
                      labelText: widget.type == AssetType.image
                          ? "Image"
                          : widget.type == AssetType.narration
                              ? "Narration"
                              : "Asset",
                      hintText: "Search for an asset...",
                    ),
                    controller: textEditingController,
                    focusNode: focusNode,
                    onSubmitted: (_) => onFieldSubmitted(),
                  );
                },
                optionsBuilder: (value) =>
                    assetDbInstance.list(value.text, widget.type),
                onSelected: widget.onAssetSelected,
              );
            }),
          ),
          const SizedBox(width: 8.0),
          Tooltip(
            message: "Add new asset",
            child: ElevatedButton(
              onPressed: _addNewAsset,
              child: const Icon(Icons.create_new_folder),
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                newAssetName = value;
              },
              onSubmitted: (_) => _saveNewAsset(),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                hoverColor: const Color(0xFFFFFFFF),
                labelText: "New asset name",
                hintText: "Type a name for your new asset.",
                errorText: newAssetError,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: _saveNewAsset,
            style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(Colors.green)),
            child: const Text("Add"),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: () {
              setState(() => newAssetPath = null);
            },
            style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(Colors.red)),
            child: const Text("Cancel"),
          ),
        ],
      );
    }
  }

  Widget _autocompleteOptionsBuilder(
      BuildContext context,
      void Function(Asset) onSelected,
      Iterable<Asset> options,
      double maxWidth) {
    int highlighted = AutocompleteHighlightedOption.of(context);

    return ConstraintsTransformBox(
      alignment: Alignment.topLeft,
      constraintsTransform: (constraints) => BoxConstraints(
        minHeight: 0,
        minWidth: 0,
        maxHeight: constraints.maxHeight,
        maxWidth: maxWidth,
      ),
      child: Material(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var option in options.toList().asMap().entries)
              InkWell(
                onTap: () {
                  onSelected(option.value);
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: option.key == highlighted
                      ? Theme.of(context).colorScheme.primary.withAlpha(224)
                      : null,
                  child: Row(
                    children: [
                      if (option.value.type == AssetType.image)
                        Icon(
                          Icons.image,
                          color:
                              option.key == highlighted ? Colors.white : null,
                        ),
                      if (option.value.type == AssetType.narration)
                        Icon(
                          Icons.mic,
                          color:
                              option.key == highlighted ? Colors.white : null,
                        ),
                      const SizedBox(width: 8.0),
                      Text(
                        option.value.name,
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: option.key == highlighted
                                  ? Colors.white
                                  : const Color.fromARGB(255, 90, 90, 90),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addNewAsset() async {
    var pickResult = await FilePicker.platform.pickFiles(allowedExtensions: [
      ...AssetType.extensionMap.keys.map((e) => e.replaceFirst(r"\.", ""))
    ]);

    var path = pickResult?.files.single.path;

    if (path != null) {
      var type = AssetType.extensionMap[p.extension(path)];
      if (type == null || widget.type != null && type != widget.type) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true, // user must tap button!
          builder: (context) {
            return AlertDialog(
              title: const Text('Invalid file type selected.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      setState(() {
        newAssetPath = pickResult?.files.single.path;
        newAssetName = null;
      });
    }
  }

  final _assetNameRegex = RegExp(r"^[a-zA-Z0-9 ]+$");
  void _saveNewAsset() async {
    var path = newAssetPath!;
    var name = newAssetName;

    if (name == null || name.isEmpty) {
      setState(() => newAssetError = "You must provide a name.");
      return;
    }

    if (!_assetNameRegex.hasMatch(name)) {
      setState(() {
        newAssetError = "Allowed characters: alphanumeric and spaces.";
      });
      return;
    }

    if (await assetDbInstance.asset(name) != null) {
      setState(() {
        newAssetError = "Asset with that name already exists.";
      });
      return;
    }

    await assetDbInstance.add(name, path);

    setState(() {
      newAssetPath = null;
      newAssetName = null;
      newAssetError = null;
    });
  }
}
