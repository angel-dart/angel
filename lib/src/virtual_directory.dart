import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_route/angel_route.dart';
import 'package:cli_util/cli_logging.dart' as cli;
import 'package:mime/mime.dart';
import 'package:pool/pool.dart';
import 'package:watcher/watcher.dart';
import 'file_info.dart';
import 'file_transformer.dart';

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

/// A static server plug-in.
class VirtualDirectory implements AngelPlugin {
  final bool debug;
  Angel _app;
  String _prefix;
  Directory _source;
  final Completer<Map<String, String>> _transformerLoad =
      new Completer<Map<String, String>>();
  final Map<String, String> _transformerMap = {};
  Pool _transformerMapMutex;
  final List<FileTransformer> _transformers = [];
  List<FileTransformer> _transformersCache;
  StreamSubscription<WatchEvent> _watch;

  /// The directory to serve files from.
  Directory get source => _source;

  /// An optional callback to run before serving files.
  final StaticFileCallback callback;

  /// Filenames to be resolved within directories as indices.
  final Iterable<String> indexFileNames;

  /// An optional public path to map requests to.
  final String publicPath;

  /// If set to `true`, files will be streamed to `res.io`, instead of added to `res.buffer`.
  final bool streamToIO;

  /// A collection of [FileTransformer] instances that will be used to dynamically compile assets, if any. **READ-ONLY**.
  List<FileTransformer> get transformers =>
      _transformersCache ??
      (_transformersCache =
          new List<FileTransformer>.unmodifiable(_transformers));

  /// If `true` (default: `false`), then transformers will not be disabled in production.
  final bool useTransformersInProduction;

  /// Completes when all [transformers] are loaded.
  Future<Map<String, String>> get transformersLoaded {
    if ((!_app.isProduction || useTransformersInProduction == true) &&
        !_transformerLoad.isCompleted)
      return _transformerLoad.future;
    else
      return new Future.value(_transformerMap);
  }

  VirtualDirectory(
      {Directory source,
      this.debug: false,
      this.indexFileNames: const ['index.html'],
      this.publicPath: '/',
      this.callback,
      this.streamToIO: false,
      this.useTransformersInProduction: false,
      Iterable<FileTransformer> transformers: const []}) {
    _prefix = publicPath.replaceAll(_straySlashes, '');
    this._transformers.addAll(transformers ?? []);

    if (source != null) {
      _source = source;
    } else {
      String dirPath = Platform.environment['ANGEL_ENV'] == 'production'
          ? './build/web'
          : './web';
      _source = new Directory(dirPath);
    }
  }

  call(Angel app) async {
    serve(_app = app);
    app.justBeforeStop.add((_) => close());
  }

  void serve(Router router) {
    // _printDebug('Source directory: ${source.absolute.path}');
    // _printDebug('Public path prefix: "$_prefix"');
    router.get('$publicPath/*',
        (RequestContext req, ResponseContext res) async {
      var path = req.path.replaceAll(_straySlashes, '');
      return servePath(path, req, res);
    });

    if ((!_app.isProduction || useTransformersInProduction == true) &&
        _transformers.isNotEmpty) {
      // Create mutex, and watch for file changes
      _transformerMapMutex = new Pool(1);
      _transformerMapMutex.request().then((resx) {
        _buildTransformerMap().then((_) => resx.release());
      });
    }
  }

  close() async {
    if (!_transformerLoad.isCompleted) {
      _transformerLoad.completeError(new StateError(
          'VirtualDirectory was closed before all transformers loaded.'));
    }

    _transformerMapMutex?.close();
    _watch?.cancel();
  }

  Future _buildTransformerMap() async {
    print('VirtualDirectory is loading transformers...');

    await for (var entity in source.list(recursive: true)) {
      if (entity is File) {
        _applyTransformers(entity.absolute.uri.toFilePath());
      }
    }

    print('VirtualDirectory finished loading transformers.');
    _transformerLoad.complete(_transformerMap);

    _watch =
        new DirectoryWatcher(source.absolute.path).events.listen((e) async {
      _transformerMapMutex.withResource(() {
        _applyTransformers(e.path);
      });
    });
  }

  void _applyTransformers(String originalAbsolutePath) {
    FileInfo file = new FileInfo.fromFile(new File(originalAbsolutePath));
    FileInfo outFile = file;
    var wasClaimed = false;

    do {
      wasClaimed = false;
      for (var transformer in _transformers) {
        var claimed = transformer.declareOutput(outFile);
        if (claimed != null) {
          outFile = claimed;
          wasClaimed = true;
        }
      }
    } while (wasClaimed);

    var finalName = outFile.filename;
    if (finalName?.isNotEmpty == true && outFile != file)
      _transformerMap[finalName] = originalAbsolutePath;
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
    if (stat.type == FileSystemEntityType.DIRECTORY)
      return await serveDirectory(new Directory(absolute), stat, req, res);
    else if (stat.type == FileSystemEntityType.FILE)
      return await serveFile(new File(absolute), stat, req, res);
    else if (stat.type == FileSystemEntityType.LINK) {
      var link = new Link(absolute);
      return await servePath(await link.resolveSymbolicLinks(), req, res);
    } else if (_transformerMapMutex != null) {
      var resx = await _transformerMapMutex.request();
      if (!_transformerMap.containsKey(absolute)) return true;
      var sourceFile = new File(_transformerMap[absolute]);
      resx.release();
      if (!await sourceFile.exists())
        return true;
      else {
        return await serveAsset(new FileInfo.fromFile(sourceFile), req, res);
      }
    } else
      return true;
  }

  Future<bool> serveDirectory(Directory directory, FileStat stat,
      RequestContext req, ResponseContext res) async {
    for (String indexFileName in indexFileNames) {
      final index =
          new File.fromUri(directory.absolute.uri.resolve(indexFileName));
      if (await index.exists()) {
        return await serveFile(index, stat, req, res);
      }

      // Try to compile an asset
      if (_transformerMap.isNotEmpty &&
          _transformerMap.containsKey(index.absolute.path)) {
        return await serveAsset(
            new FileInfo.fromFile(
                new File(_transformerMap[index.absolute.path])),
            req,
            res);
      }
    }

    return true;
  }

  Future<bool> serveFileOld(
      File file, FileStat stat, RequestContext req, ResponseContext res) async {
    // _printDebug('Sending file ${file.absolute.path}...');
    // _printDebug('MIME type for ${file.path}: ${lookupMimeType(file.path)}');
    res.statusCode = 200;

    if (callback != null) {
      var r = callback(file, req, res);
      r = r is Future ? await r : r;
      if (r != null && r != true) return r;
    }

    res.headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);

    if (streamToIO == true) {
      res
        ..io.headers.set(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path))
        ..io.headers.set(HttpHeaders.CONTENT_ENCODING, 'gzip')
        ..end()
        ..willCloseItself = true;

      await file.openRead().transform(GZIP.encoder).pipe(res.io);
    } else
      await res.sendFile(file);
    return false;
  }

  void _ensureContentTypeAllowed(String mimeType, RequestContext req) {
    var value = req.headers.value(HttpHeaders.ACCEPT);
    bool acceptable = value == null ||
        value?.isNotEmpty != true ||
        (mimeType?.isNotEmpty == true && value?.contains(mimeType) == true) ||
        value?.contains('*/*') == true;
    if (!acceptable)
      throw new AngelHttpException(
          new UnsupportedError(
              'Client requested $value, but server wanted to send $mimeType.'),
          statusCode: HttpStatus.NOT_ACCEPTABLE,
          message: '406 Not Acceptable');
  }

  Future<bool> serveFile(
      File file, FileStat stat, RequestContext req, ResponseContext res) async {
    // _printDebug('Sending file ${file.absolute.path}...');
    // _printDebug('MIME type for ${file.path}: ${lookupMimeType(file.path)}');
    res.statusCode = 200;

    if (callback != null) {
      var r = callback(file, req, res);
      r = r is Future ? await r : r;
      if (r != null && r != true) return r;
    }

    var type = lookupMimeType(file.path);
    _ensureContentTypeAllowed(type, req);
    res.headers[HttpHeaders.CONTENT_TYPE] = type;

    if (streamToIO == true) {
      res
        ..io.headers.set(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path))
        ..io.headers.set(HttpHeaders.CONTENT_ENCODING, 'gzip')
        ..end()
        ..willCloseItself = true;

      await file.openRead().transform(GZIP.encoder).pipe(res.io);
    } else
      await res.sendFile(file);
    return false;
  }

  Future<bool> serveAsset(
      FileInfo fileInfo, RequestContext req, ResponseContext res) async {
    var file = await compileAsset(fileInfo);
    if (file == null) return true;
    _ensureContentTypeAllowed(file.mimeType, req);
    res.headers[HttpHeaders.CONTENT_TYPE] = file.mimeType;
    res.statusCode = 200;

    if (streamToIO == true) {
      res
        ..statusCode = 200
        ..io.headers.set(HttpHeaders.CONTENT_TYPE, file.mimeType)
        ..io.headers.set(HttpHeaders.CONTENT_ENCODING, 'gzip')
        ..end()
        ..willCloseItself = true;
      await file.content.transform(GZIP.encoder).pipe(res.io);
    } else {
      await file.content.forEach(res.buffer.add);
    }

    return false;
  }

  /// Applies all [_transformers] to an input [file], if any.
  Future<FileInfo> compileAsset(FileInfo file) async {
    var iterations = 0;
    FileInfo result = file;
    bool wasTransformed = false;

    do {
      wasTransformed = false;
      String originalName = file.filename;
      for (var transformer in _transformers) {
        if (++iterations >= 100) {
          print(
              'VirtualDirectory has tried 100 times to compile ${file.filename}. Perhaps one of your transformers is not changing the output file\'s extension.');
          throw new AngelHttpException(new StackOverflowError(),
              statusCode: 500);
        } else if (iterations < 100) iterations++;
        var claimed = transformer.declareOutput(result);
        if (claimed != null) {
          result = await transformer.transform(result);
          wasTransformed = true;
        }
      }

      // Don't re-compile infinitely...
      if (result.filename == originalName) wasTransformed = false;
    } while (wasTransformed);

    return result == file ? null : result;
  }

  /// Builds assets to disk using [transformers].
  Future buildToDisk() async {
    var l = new cli.Logger.standard();
    print('Building assets in "${source.absolute.path}"...');

    await for (var entity in source.list(recursive: true)) {
      if (entity is File) {
        var p = l.progress('Building "${entity.absolute.path}"');

        try {
          var asset = new FileInfo.fromFile(entity);
          var compiled = await compileAsset(asset);
          if (compiled == null)
            p.finish(
                message:
                    '"${entity.absolute.path}" did not require compilation; skipping it.');
          else {
            var outFile = new File(compiled.filename);
            if (!await outFile.exists()) await outFile.create(recursive: true);
            var sink = outFile.openWrite();
            await compiled.content.pipe(sink);
            p.finish(
                message:
                    'Built "${entity.absolute.path}" to "${compiled.filename}".',
                showTiming: true);
          }
        } on AngelHttpException {
          // Ignore 500
        } catch (e, st) {
          p.finish(message: 'Failed to build "${entity.absolute.path}".');
          stderr..writeln(e)..writeln(st);
        }
      }
    }

    print('Build of assets in "${source.absolute.path}" complete.');
  }
}
