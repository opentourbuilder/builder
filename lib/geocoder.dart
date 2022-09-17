import 'dart:convert';
import 'dart:io';

import '/utils/utils.dart';

import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class Place {
  const Place({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
  });

  final String formattedAddress;
  final double lat;
  final double lng;
}

abstract class GeocoderService {
  Future<List<Place>> forwardGeocode(String address);
  Future<List<Place>> reverseGeocode(double lat, double lng);
}

class GeocodioService implements GeocoderService {
  GeocodioService(this.apiKey);

  final String apiKey;

  static GeocodioService? _instance;

  static Future<GeocodioService> fromConfig(String path) async {
    final config = jsonDecode(await File(path).readAsString());
    final apiKey = config["api_key"];

    return GeocodioService(apiKey);
  }

  static Future<GeocodioService> get instance async {
    if (_instance != null) {
      return _instance!;
    } else {
      _instance ??= await GeocodioService.fromConfig(
          path.join(getInstallDirectory(), "geocodio.json"));
      return _instance!;
    }
  }

  Uri _apiUrl(String endpoint, Map<String, dynamic> queryParameters) =>
      Uri.https('api.geocod.io', '/v1.7/$endpoint', {
        'api_key': apiKey,
        ...queryParameters,
      });

  List<Place> _parseResponse(dynamic respJson) =>
      (respJson["results"] as List<dynamic>)
          .map((res) => Place(
                lat: res["location"]["lat"],
                lng: res["location"]["lng"],
                formattedAddress: res["formatted_address"],
              ))
          .toList();

  @override
  Future<List<Place>> forwardGeocode(String address) async {
    var resp = await http.get(_apiUrl('geocode', {'q': address}));
    var respJson = jsonDecode(resp.body);
    return _parseResponse(respJson);
  }

  @override
  Future<List<Place>> reverseGeocode(double lat, double lng) async {
    var resp = await http.get(_apiUrl('reverse', {'q': '$lat,$lng'}));
    var respJson = jsonDecode(resp.body);
    return _parseResponse(respJson);
  }
}
