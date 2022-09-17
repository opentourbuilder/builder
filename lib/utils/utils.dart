import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

String getInstallDirectory() => kDebugMode
    ? path.join(Directory.current.path, "install")
    : path.dirname(Platform.resolvedExecutable);
