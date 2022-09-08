import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as path;

abstract class Router {
  Future<Iterable<LatLng>> route(List<LatLng> waypoints);
}

typedef _LotyrNewFunc = ffi.Pointer Function(
    ffi.Pointer<ffi.Pointer>, ffi.Pointer<Utf8>);
typedef _LotyrNew = _LotyrNewFunc;
typedef _LotyrFreeFunc = ffi.Pointer Function(ffi.Pointer);
typedef _LotyrFree = _LotyrFreeFunc;
typedef _LotyrRouteFunc = ffi.Pointer Function(
    ffi.Pointer, ffi.Pointer<Utf8>, ffi.Pointer<ffi.Pointer<Utf8>>);
typedef _LotyrRoute = _LotyrRouteFunc;
typedef _LotyrErrorMessageFunc = ffi.Pointer<Utf8> Function(ffi.Pointer);
typedef _LotyrErrorMessage = _LotyrErrorMessageFunc;
typedef _LotyrErrorFreeFunc = ffi.Void Function(ffi.Pointer);
typedef _LotyrErrorFree = void Function(ffi.Pointer);

class _RouteMessage {
  const _RouteMessage({required this.request});

  final String request;
}

class _RouteResponse {
  const _RouteResponse({required this.response});

  final String response;
}

class _ErrorResponse {
  const _ErrorResponse({required this.message});

  final String message;
}

class ValhallaRouter implements Router {
  late final StreamQueue<dynamic> events;
  late final SendPort messages;
  late final Isolate worker;

  ValhallaRouter() {
    final workerRecvPort = ReceivePort();
    events = StreamQueue(workerRecvPort);
    events.next.then((sendPort) {
      messages = sendPort;
    });
    Isolate.spawn(_isolate, workerRecvPort.sendPort)
        .then((spawned) => worker = spawned);
  }

  @override
  Future<List<LatLng>> route(Iterable<LatLng> waypoints) async {
    final requestJson = {
      "locations": [
        for (final waypoint in waypoints)
          {
            "lat": waypoint.latitude,
            "lon": waypoint.longitude,
          },
      ],
      "costing": "auto",
      "directions_options": {
        "units": "miles",
      },
    };

    final requestText = jsonEncode(requestJson);

    messages.send(_RouteMessage(request: requestText));

    final response = await events.next;

    if (response is _RouteResponse) {
      final responseJson = jsonDecode(response.response);

      return (responseJson["trip"]["legs"] as List<dynamic>)
          .map((leg) => mtk.PolygonUtil.decode(leg["shape"])
              .map((ll) => LatLng(ll.latitude / 10, ll.longitude / 10))
              .toList())
          .toList()
          .reduce((value, element) => value + element);
    } else if (response is _ErrorResponse) {
      throw Exception(response.message);
    } else {
      throw Exception("Unexpected response from worker isolate");
    }
  }

  static Future<void> _isolate(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    final pathBase = kDebugMode
        ? Directory.current.path
        : path.dirname(Platform.resolvedExecutable);

    final String? libraryPath;
    if (Platform.isLinux) {
      libraryPath = path.join(pathBase, 'lotyr', 'liblotyr.so');
    } else if (Platform.isMacOS) {
      libraryPath = path.join(pathBase, 'lotyr', 'liblotyr.dylib');
    } else if (Platform.isWindows) {
      libraryPath = path.join(pathBase, 'lotyr', 'lotyr.dll');
    } else {
      libraryPath = null;
    }

    final dylib = ffi.DynamicLibrary.open(libraryPath!);

    final lotyrNew = dylib
        .lookup<ffi.NativeFunction<_LotyrNewFunc>>('lotyr_new')
        .asFunction<_LotyrNew>();
    final lotyrFree = dylib
        .lookup<ffi.NativeFunction<_LotyrFreeFunc>>('lotyr_free')
        .asFunction<_LotyrFree>();
    final lotyrRoute = dylib
        .lookup<ffi.NativeFunction<_LotyrRouteFunc>>('lotyr_route')
        .asFunction<_LotyrRoute>();
    final lotyrErrorMessage = dylib
        .lookup<ffi.NativeFunction<_LotyrErrorMessageFunc>>(
            'lotyr_error_message')
        .asFunction<_LotyrErrorMessage>();
    final lotyrErrorFree = dylib
        .lookup<ffi.NativeFunction<_LotyrErrorFreeFunc>>('lotyr_error_free')
        .asFunction<_LotyrErrorFree>();

    // this will be the pointer to the Lotyr instance
    final lotyrPtr = malloc<ffi.Pointer>();

    final configPath = path.join(pathBase, 'lotyr', 'valhalla.json');
    final configPathNative = configPath.toNativeUtf8(allocator: malloc);
    final createError = lotyrNew(lotyrPtr, configPathNative);
    malloc.free(configPathNative);
    if (createError.address != 0) {
      // failed somehow
      // TODO: do something with the error
      lotyrErrorFree(createError);
      malloc.free(lotyrPtr);
      return;
    }

    // get the Lotyr instance without the extra level of pointer indirection
    final lotyr = lotyrPtr.value;

    await for (final message in receivePort) {
      if (message is _RouteMessage) {
        final requestNative = message.request.toNativeUtf8(allocator: malloc);
        final responseNativePtr = malloc<ffi.Pointer<Utf8>>();

        final routeError = lotyrRoute(lotyr, requestNative, responseNativePtr);

        malloc.free(requestNative);

        if (routeError.address != 0) {
          // failed somehow
          final messageNative = lotyrErrorMessage(routeError);
          final message = messageNative.toDartString();
          lotyrErrorFree(routeError);
          sendPort.send(_ErrorResponse(message: message));
        } else {
          final responseNative = responseNativePtr.value;
          final response = responseNative.toDartString();

          malloc.free(responseNativePtr);
          malloc.free(responseNative);

          sendPort.send(_RouteResponse(response: response));
        }
      }
    }
  }
}
