library angel_static;

import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mime/mime.dart' show lookupMimeType;

Future<bool> _sendFile(File file, ResponseContext res) async {
  res
    ..willCloseItself = true
    ..header(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path))
    ..status(200);
  await res.streamFile(file);
  await res.underlyingResponse.close();
  return false;
}

/// Serves files statically from a given directory.
RequestMiddleware serveStatic({
Directory sourceDirectory,
List<String> indexFileNames: const['index.html'],
String virtualRoot: '/'
}) {
  if (sourceDirectory == null) {
    String dirPath = Platform.environment['ANGEL_ENV'] == 'production'
        ? './build/web'
        : './web';
    sourceDirectory = new Directory(dirPath);
  }

  RegExp requestingIndex = new RegExp(r'^((\/)|(\\))*$');

  return (RequestContext req, ResponseContext res) async {
    String requested = req.path.replaceAll(new RegExp(r'^\/'), '');
    File file = new File.fromUri(
        sourceDirectory.absolute.uri.resolve(requested));
    if (await file.exists()) {
      return await _sendFile(file, res);
    }

    // Try to resolve index
    String relative = req.path.replaceFirst(virtualRoot, "")
        .replaceAll(new RegExp(r'^\/+'), "");
    if (requestingIndex.hasMatch(relative) || relative.isEmpty) {
      for (String indexFileName in indexFileNames) {
        file =
        new File.fromUri(sourceDirectory.absolute.uri.resolve(indexFileName));
        if (await file.exists()) {
          return await _sendFile(file, res);
        }
      }
    }

    return true;
  };
}

