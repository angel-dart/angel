import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_route/angel_route.dart';
import 'package:mime/mime.dart';

typedef StaticFileCallback(File file, RequestContext req, ResponseContext res);

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

class VirtualDirectory implements AngelPlugin {
  final bool debug;
  String _prefix;
  Directory _source;
  Directory get source => _source;
  final StaticFileCallback callback;
  final List<String> indexFileNames;
  final String publicPath;

  /// If set to `true`, files will be streamed to `res.io`, instead of added to `res.buffer`.
  final bool streamToIO;

  VirtualDirectory(
      {Directory source,
      this.debug: false,
      this.indexFileNames: const ['index.html'],
      this.publicPath: '/',
      this.callback,
      this.streamToIO: false}) {
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

  call(Angel app) async => serve(app);

  void serve(Router router) {
    _printDebug('Source directory: ${source.absolute.path}');
    _printDebug('Public path prefix: "$_prefix"');
    router.get('$publicPath/*',
        (RequestContext req, ResponseContext res) async {
      var path = req.path.replaceAll(_straySlashes, '');
      return servePath(path, req, res);
    });
  }

  servePath(String path, RequestContext req, ResponseContext res) async {
    if (_prefix.isNotEmpty) {
      path = path.replaceAll(new RegExp('^' + _pathify(_prefix)), '');
    }

    if (path.isEmpty) path = '.';

    var absolute = source.absolute.uri.resolve(path).toFilePath();
    var stat = await FileStat.stat(absolute);
    return await serveStat(absolute, stat, req, res);
  }

  Future<bool> serveStat(String absolute, FileStat stat, RequestContext req,
      ResponseContext res) async {
    if (stat.type == FileSystemEntityType.NOT_FOUND)
      return true;
    else if (stat.type == FileSystemEntityType.DIRECTORY)
      return await serveDirectory(new Directory(absolute), req, res);
    else if (stat.type == FileSystemEntityType.FILE)
      return await serveFile(new File(absolute), req, res);
    else if (stat.type == FileSystemEntityType.LINK) {
      var link = new Link(absolute);
      return await servePath(await link.resolveSymbolicLinks(), req, res);
    } else
      return true;
  }

  Future<bool> serveFile(
      File file, RequestContext req, ResponseContext res) async {
    _printDebug('Sending file ${file.absolute.path}...');
    _printDebug('MIME type for ${file.path}: ${lookupMimeType(file.path)}');
    res.statusCode = 200;

    if (callback != null) {
      var r = callback(file, req, res);
      r = r is Future ? await r : r;
      if (r != null && r != true) return r;
    }

    res.headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);

    if (streamToIO == true)
      await res.streamFile(file);
    else
      await res.sendFile(file);
    return false;
  }

  Future<bool> serveDirectory(
      Directory directory, RequestContext req, ResponseContext res) async {
    for (String indexFileName in indexFileNames) {
      final index =
          new File.fromUri(directory.absolute.uri.resolve(indexFileName));
      if (await index.exists()) {
        return await serveFile(index, req, res);
      }
    }

    return true;
  }
}
