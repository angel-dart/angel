import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'package:mime/mime.dart';

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

/// A static server plug-in.
class VirtualDirectory {
  String _prefix;
  Directory _source;

  /// The directory to serve files from.
  Directory get source => _source;

  /// An optional callback to run before serving files.
  final Function(File file, RequestContext req, ResponseContext res) callback;

  final Angel app;
  final FileSystem fileSystem;

  /// Filenames to be resolved within directories as indices.
  final Iterable<String> indexFileNames;

  /// An optional public path to map requests to.
  final String publicPath;

  VirtualDirectory(this.app, this.fileSystem,
      {Directory source,
      this.indexFileNames: const ['index.html'],
      this.publicPath: '/',
      this.callback}) {
    _prefix = publicPath.replaceAll(_straySlashes, '');
    if (source != null) {
      _source = source;
    } else {
      String dirPath = app.isProduction ? './build/web' : './web';
      _source = fileSystem.directory(dirPath);
    }
  }

  /// Responds to incoming HTTP requests.
  Future<bool> handleRequest(RequestContext req, ResponseContext res) {
    if (req.method != 'GET') return new Future<bool>.value(true);
    var path = req.path.replaceAll(_straySlashes, '');

    if (_prefix?.isNotEmpty == true && !path.startsWith(_prefix))
      return new Future<bool>.value(true);

    return servePath(path, req, res);
  }

  /// A handler that serves the file at the given path, unless the user has requested that path.
  RequestMiddleware pushState(String path) {
    var vPath = path.replaceAll(_straySlashes, '');
    if (_prefix?.isNotEmpty == true) vPath = '$_prefix/$vPath';

    return (RequestContext req, ResponseContext res) {
      var path = req.path.replaceAll(_straySlashes, '');
      if (path == vPath) return new Future<bool>.value(true);
      return servePath(vPath, req, res);
    };
  }

  /// Writes the file at the given virtual [path] to a response.
  Future<bool> servePath(
      String path, RequestContext req, ResponseContext res) async {
    if (_prefix.isNotEmpty) {
      // Only replace the *first* incidence
      // Resolve: https://github.com/angel-dart/angel/issues/41
      path = path.replaceFirst(new RegExp('^' + _pathify(_prefix)), '');
    }

    if (path.isEmpty) path = '.';
    path = path.replaceAll(_straySlashes, '');

    var absolute = source.absolute.uri.resolve(path).toFilePath();
    var stat = await fileSystem.stat(absolute);
    return await serveStat(absolute, stat, req, res);
  }

  /// Writes the file at the path given by the [stat] to a response.
  Future<bool> serveStat(String absolute, FileStat stat, RequestContext req,
      ResponseContext res) async {
    if (stat.type == FileSystemEntityType.DIRECTORY)
      return await serveDirectory(
          fileSystem.directory(absolute), stat, req, res);
    else if (stat.type == FileSystemEntityType.FILE)
      return await serveFile(fileSystem.file(absolute), stat, req, res);
    else if (stat.type == FileSystemEntityType.LINK) {
      var link = fileSystem.link(absolute);
      return await servePath(await link.resolveSymbolicLinks(), req, res);
    } else
      return true;
  }

  /// Serves the index file of a [directory], if it exists.
  Future<bool> serveDirectory(Directory directory, FileStat stat,
      RequestContext req, ResponseContext res) async {
    for (String indexFileName in indexFileNames) {
      final index =
          fileSystem.file(directory.absolute.uri.resolve(indexFileName));
      if (await index.exists()) {
        return await serveFile(index, stat, req, res);
      }
    }

    return true;
  }

  void _ensureContentTypeAllowed(String mimeType, RequestContext req) {
    var value = req.headers.value('accept');
    bool acceptable = value == null ||
        value?.isNotEmpty != true ||
        (mimeType?.isNotEmpty == true && value?.contains(mimeType) == true) ||
        value?.contains('*/*') == true;
    if (!acceptable)
      throw new AngelHttpException(
          new UnsupportedError(
              'Client requested $value, but server wanted to send $mimeType.'),
          statusCode: 406,
          message: '406 Not Acceptable');
  }

  /// Writes the contents of a file to a response.
  Future<bool> serveFile(
      File file, FileStat stat, RequestContext req, ResponseContext res) async {
    res.statusCode = 200;

    if (callback != null) {
      var r = callback(file, req, res);
      r = r is Future ? await r : r;
      if (r != null && r != true) return r;
    }

    var type = lookupMimeType(file.path) ?? 'application/octet-stream';
    _ensureContentTypeAllowed(type, req);
    res.headers['content-type'] = type;

    await file.openRead().pipe(res);
    return false;
  }
}
