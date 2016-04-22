library angel_static;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mime/mime.dart' show lookupMimeType;

/// Serves files statically from a given directory.
Middleware serveStatic([Directory sourceDirectory]) {
  if (sourceDirectory == null) {
    String dirPath = Platform.environment['ANGEL_ENV'] == 'production'
        ? './build/web'
        : './web';
    sourceDirectory = new Directory(dirPath);
  }

  return (RequestContext req, ResponseContext res) async {
    String requested = req.path.replaceAll(new RegExp(r'^\/'), '');
    File file = new File.fromUri(
        sourceDirectory.absolute.uri.resolve(requested));
    if (await file.exists()) {
      res
        ..willCloseItself = true
        ..header(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path))
        ..status(200);
      await res.streamFile(file);
      await res.underlyingResponse.close();
      return false;
    }

    return true;
  };
}

