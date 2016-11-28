import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_route/angel_route.dart';
import 'package:mime/mime.dart' show lookupMimeType;

final RegExp _param = new RegExp(r':([A-Za-z0-9_]+)(\((.+)\))?');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

String _pathify(String path) {
  var p = path.replaceAll(_straySlashes, '');

  Map<String, String> replace = {};

  for (Match match in _param.allMatches(p)) {
    if (match[3] != null) replace[match[0]] = ':${match[1]}';
  }

  replace.forEach((k, v) {
    p = p.replaceAll(k, v);
  });

  return p;
}

class VirtualDirectory {
  final bool debug;
  String _prefix;
  Directory _source;
  Directory get source => _source;
  final List<String> indexFileNames;
  final String publicPath;

  VirtualDirectory(
      {Directory source,
      this.debug: false,
      this.indexFileNames: const ['index.html'],
      this.publicPath: '/'}) {
    _prefix = publicPath.replaceAll(_straySlashes, '');

    if (source != null) {
      _source = source;
    } else {
      String dirPath = Platform.environment['ANGEL_ENV'] == 'production'
          ? './build/web'
          : './web';
      _source = new Directory(dirPath);
    }
  }

  _printDebug(msg) {
    if (debug) print(msg);
  }

  call(AngelBase app) async => serve(app);

  Future<bool> sendFile(File file, ResponseContext res) async {
    _printDebug('Streaming file ${file.absolute.path}...');
    res
      ..willCloseItself = true
      ..header(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path))
      ..status(200);
    await res.streamFile(file);
    await res.io.close();
    return false;
  }

  void serve(Router router) {
    _printDebug('Source directory: ${source.absolute.path}');
    _printDebug('Public path prefix: "$_prefix"');

    handler(RequestContext req, ResponseContext res) async {
      var path = req.path.replaceAll(_straySlashes, '');

      return serveFile(path, res);
    }

    router.get('$publicPath/*', handler);
  }

  serveFile(String path, ResponseContext res) async {
    if (_prefix.isNotEmpty) {
      path = path.replaceAll(new RegExp('^' + _pathify(_prefix)), '');
    }

    final file = new File.fromUri(source.absolute.uri.resolve(path));
    _printDebug('Attempting to statically serve file: ${file.absolute.path}');

    if (await file.exists()) {
      return sendFile(file, res);
    } else {
      // Try to resolve index
      if (path.isEmpty) {
        for (String indexFileName in indexFileNames) {
          final index =
              new File.fromUri(source.absolute.uri.resolve(indexFileName));
          if (await index.exists()) {
            return await sendFile(index, res);
          }
        }
      } else {
        _printDebug('File "$path" does not exist, and is not an index.');
        return true;
      }
    }
  }
}
