class AssetModel {
  AssetModel();

  String id = "";

  factory AssetModel.fromJson(String data) => AssetModel()..id = data;

  dynamic toJson() => id;
}
