import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

String getInstallDirectory() {
  if (kDebugMode) {
    if (!Platform.isWindows) {
      return path.join(Directory.current.path, "install");
    } else {
      return path.join(
          Platform.environment["LOCALAPPDATA"]!, "OpenTourBuilderDebugInstall");
    }
  } else {
    return path.dirname(Platform.resolvedExecutable);
  }
}
