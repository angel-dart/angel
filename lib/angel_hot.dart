import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:glob/glob.dart';
import 'package:html_builder/elements.dart';
import 'package:html_builder/html_builder.dart';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:watcher/watcher.dart';

/// A typedef over a function that returns a fresh [Angel] instance, whether synchronously or asynchronously.
typedef FutureOr<Angel> AngelGenerator();

class HotReloader {
  VMServiceClient _client;
  final List _paths = [];
  final StringRenderer _renderer = new StringRenderer(pretty: false);
  final Queue<HttpRequest> _requestQueue = new Queue<HttpRequest>();
  Angel _server;
  Duration _timeout;

  /// Invoked to load a new instance of [Angel] on file changes.
  final AngelGenerator generator;

  /// The maximum amount of time to queue incoming requests for if there is no [server] available.
  ///
  /// If the timeout expires, then the request will be immediately terminated with a `502 Bad Gateway` error.
  /// Default: `5s`
  Duration get timeout => _timeout;

  /// A URL pointing to the Dart VM service.
  ///
  /// Default: `ws://localhost:8181/ws`.
  final String vmServiceUrl;

  /// Initializes a hot reloader that proxies the server created by [generator].
  ///
  /// [paths] can contain [FileSystemEntity], [Uri], [String] and [Glob] only.
  /// URI's can be `package:` URI's as well.
  HotReloader(this.generator, Iterable paths,
      {Duration timeout, this.vmServiceUrl: 'ws://localhost:8181/ws'}) {
    _timeout = timeout ?? new Duration(seconds: 5);
    _paths.addAll(paths ?? []);
  }

  Future handleRequest(HttpRequest request) async {
    if (_server != null)
      return await _server.handleRequest(request);
    else if (timeout == null)
      _requestQueue.add(request);
    else {
      _requestQueue.add(request);
      new Timer(timeout, () {
        if (_requestQueue.remove(request)) {
          // Send 502 response
          var doc = html(lang: 'en', c: [
            head(c: [
              meta(
                  name: 'viewport',
                  content: 'width=device-width, initial-scale=1'),
              title(c: [text('502 Bad Gateway')])
            ]),
            body(c: [
              h1(c: [text('502 Bad Gateway')]),
              i(c: [
                text('Request timed out after ${timeout.inMilliseconds}ms.')
              ])
            ])
          ]);

          var response = request.response;
          response.statusCode = HttpStatus.BAD_GATEWAY;
          response.headers
            ..contentType = ContentType.HTML
            ..set(HttpHeaders.SERVER, 'angel_hot');

          if (request.headers
                  .value(HttpHeaders.ACCEPT_ENCODING)
                  ?.toLowerCase()
                  ?.contains('gzip') ==
              true) {
            response
              ..headers.set(HttpHeaders.CONTENT_ENCODING, 'gzip')
              ..add(GZIP.encode(UTF8.encode(_renderer.render(doc))));
          } else
            response.write(_renderer.render(doc));
          response.close();
        }
      });
    }
  }

  Future<Angel> _generateServer() async {
    var s = await generator() as Angel;
    await Future.forEach(s.justBeforeStart, s.configure);
    s.optimizeForProduction();
    return s;
  }

  /// Starts listening to requests and filesystem events.
  Future<HttpServer> startServer([address, int port]) async {
    if (_paths?.isNotEmpty != true)
      print(
          'WARNING: You have instantiated a HotReloader without providing any filesystem paths to watch.');

    var s = _server = await _generateServer();
    while (!_requestQueue.isEmpty)
      await s.handleRequest(_requestQueue.removeFirst());
    await _listenToFilesystem();

    var server = await HttpServer.bind(
        address ?? InternetAddress.LOOPBACK_IP_V4, port ?? 0);
    server.listen(handleRequest);
    return server;
  }

  _listenToFilesystem() async {
    for (var path in _paths) {
      if (path is String) {
        await _listenToStat(path);
      } else if (path is Glob) {
        await for (var entity in path.list()) {
          await _listenToStat(entity.path);
        }
      } else if (path is FileSystemEntity) {
        await _listenToStat(path.path);
      } else if (path is Uri) {
        if (path.scheme == 'package') {
          var uri = await Isolate.resolvePackageUri(path);
          await _listenToStat(uri.toFilePath());
        } else
          await _listenToStat(path.toFilePath());
      } else {
        throw new ArgumentError(
            'Hot reload paths must be a FileSystemEntity, a Uri, a String or a Glob. You provided: $path');
      }
    }
  }

  _listenToStat(String path) async {
    _listen() async {
      try {
        var stat = await FileStat.stat(path);
        if (stat.type == FileSystemEntityType.LINK) {
          var lnk = new Link(path);
          var p = await lnk.resolveSymbolicLinks();
          return await _listenToStat(p);
        } else if (stat.type == FileSystemEntityType.FILE) {
          var file = new File(path);
          if (!await file.exists()) return null;
        } else if (stat.type == FileSystemEntityType.DIRECTORY) {
          var dir = new Directory(path);
          if (!await dir.exists()) return null;
        } else
          return null;

        var watcher = new Watcher(path);
        //await watcher.ready;
        watcher.events.listen(_handleWatchEvent);
        print('Listening for file changes at ${path}...');
        return true;
      } catch (e) {
        if (e is! FileSystemException) rethrow;
      }
    }

    var r = await _listen();

    if (r == null) {
      print(
          'WARNING: Unable to watch path "$path" from working directory "${Directory.current.path}". Please ensure that it exists.');
    }
  }

  _handleWatchEvent(WatchEvent e) async {
    print('${e.path} changed. Reloading server...');
    var old = _server;
    if (old != null) Future.forEach(old.justBeforeStop, old.configure);
    _server = null;

    _client ??=
        new VMServiceClient.connect(vmServiceUrl ?? 'ws://localhost:8181/ws');
    var vm = await _client.getVM();
    var mainIsolate = vm.isolates.first;
    var runnable = await mainIsolate.loadRunnable();
    var report = await runnable.reloadSources();

    if (!report.status) {
      stderr.writeln('Hot reload failed!!!');
      stderr.writeln(report.message);
      exit(1);
    }

    var s = await _generateServer();
    _server = s;
    while (!_requestQueue.isEmpty)
      await s.handleRequest(_requestQueue.removeFirst());
  }
}
