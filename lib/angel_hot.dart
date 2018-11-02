import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_websocket/server.dart';
import 'package:charcode/ascii.dart';
import 'package:glob/glob.dart';
import 'package:html_builder/elements.dart';
import 'package:html_builder/html_builder.dart';
import 'package:io/ansi.dart';
import 'package:vm_service_lib/vm_service_lib.dart' as vm;
import 'package:vm_service_lib/vm_service_lib_io.dart' as vm;
import 'package:watcher/watcher.dart';

/// A utility class that watches the filesystem for changes, and starts new instances of an Angel server.
class HotReloader {
  vm.VmService _client;
  vm.IsolateRef _mainIsolate;
  final StreamController<WatchEvent> _onChange =
      new StreamController<WatchEvent>.broadcast();
  final List _paths = [];
  final StringRenderer _renderer = new StringRenderer(pretty: false);
  final Queue<HttpRequest> _requestQueue = new Queue<HttpRequest>();
  AngelHttp _server;
  Duration _timeout;
  vm.VM _vmachine;

  /// If `true` (default), then developers can `press 'r' to reload` the application on-the-fly.
  ///
  /// This option triggers printing a Flutter-like output to the terminal.
  final bool enableHotkeys;

  /// Invoked to load a new instance of [Angel] on file changes.
  final FutureOr<Angel> Function() generator;

  /// Fires whenever a file change. You might consider using this to trigger
  /// page reloads in a client.
  Stream<WatchEvent> get onChange => _onChange.stream;

  /// The maximum amount of time to queue incoming requests for if there is no [server] available.
  ///
  /// If the timeout expires, then the request will be immediately terminated with a `502 Bad Gateway` error.
  /// Default: `5s`
  Duration get timeout => _timeout;

  /// The Dart VM service host.
  ///
  /// Default: `localhost`.
  final String vmServiceHost;

  /// The port to connect to the Dart VM service.
  ///
  /// Default: `8181`.
  final int vmServicePort;

  /// Initializes a hot reloader that proxies the server created by [generator].
  ///
  /// [paths] can contain [FileSystemEntity], [Uri], [String] and [Glob] only.
  /// URI's can be `package:` URI's as well.
  HotReloader(this.generator, Iterable paths,
      {Duration timeout,
      this.vmServiceHost: 'localhost',
      this.vmServicePort: 8181,
      this.enableHotkeys: true}) {
    _timeout = timeout ?? new Duration(seconds: 5);
    _paths.addAll(paths ?? []);
  }

  Future close() async {
    _onChange.close();
  }

  void sendError(HttpRequest request, int status, String title_, e) {
    var doc = html(lang: 'en', c: [
      head(c: [
        meta(name: 'viewport', content: 'width=device-width, initial-scale=1'),
        title(c: [text(title_)])
      ]),
      body(c: [
        h1(c: [text(title_)]),
        i(c: [text(e.toString())])
      ])
    ]);

    var response = request.response;
    response.statusCode = HttpStatus.badGateway;
    response.headers
      ..contentType = ContentType.html
      ..set(HttpHeaders.serverHeader, 'angel_hot');

    if (request.headers
            .value(HttpHeaders.acceptEncodingHeader)
            ?.toLowerCase()
            ?.contains('gzip') ==
        true) {
      response
        ..headers.set(HttpHeaders.contentEncodingHeader, 'gzip')
        ..add(gzip.encode(utf8.encode(_renderer.render(doc))));
    } else
      response.write(_renderer.render(doc));
    response.close();
  }

  Future _handle(HttpRequest request) {
    return _server.handleRequest(request);
  }

  Future handleRequest(HttpRequest request) async {
    if (_server != null)
      return await _handle(request);
    else if (timeout == null)
      _requestQueue.add(request);
    else {
      _requestQueue.add(request);
      new Timer(timeout, () {
        if (_requestQueue.remove(request)) {
          // Send 502 response
          sendError(request, HttpStatus.badGateway, '502 Bad Gateway',
              'Request timed out after ${timeout.inMilliseconds}ms.');
        }
      });
    }
  }

  Future<AngelHttp> _generateServer() async {
    var s = await generator();
    await Future.forEach(s.startupHooks, s.configure);
    s.optimizeForProduction();
    return new AngelHttp(s);
  }

  /// Starts listening to requests and filesystem events.
  Future<HttpServer> startServer([address, int port]) async {
    var isHot = true;
    _server = await _generateServer();

    if (_paths?.isNotEmpty != true)
      print(yellow.wrap(
          'WARNING: You have instantiated a HotReloader without providing any filesystem paths to watch.'));

    if (!Platform.executableArguments.contains('--observe') &&
        !Platform.executableArguments.contains('--enable-vm-service')) {
      stderr.writeln(yellow.wrap(
          'WARNING: You have instantiated a HotReloader without passing `--enable-vm-service` or `--observe` to the Dart VM. Hot reloading will be disabled.'));
      isHot = false;
    } else {
      _client = await vm.vmServiceConnect(
          vmServiceHost ?? 'localhost', vmServicePort ?? 8181);
      _vmachine ??= await _client.getVM();
      _mainIsolate ??= _vmachine.isolates.first;
      await _client.setExceptionPauseMode(_mainIsolate.id, 'None');
      await _listenToFilesystem();
    }

    _onChange.stream
        //.transform(new _Debounce(new Duration(seconds: 1)))
        .listen(_handleWatchEvent);

    while (!_requestQueue.isEmpty) await _handle(_requestQueue.removeFirst());
    var server = await HttpServer.bind(address ?? '127.0.0.1', port ?? 0);
    server.listen(handleRequest);

    // Print a Flutter-like prompt...
    if (enableHotkeys) {
      var serverUri = new Uri(
          scheme: 'http', host: server.address.address, port: server.port);
      var host = vmServiceHost == 'localhost' ? '127.0.0.1' : vmServiceHost;
      var observatoryUri =
          new Uri(scheme: 'http', host: host, port: vmServicePort);

      print(styleBold.wrap(
          '\n🔥  To hot reload changes while running, press "r". To hot restart (and rebuild state), press "R".'));
      stdout.write('Your Angel server is listening at: ');
      print(wrapWith('$serverUri', [cyan, styleUnderlined]));
      stdout.write(
          'An Observatory debugger and profiler on ${Platform.operatingSystem} is available at: ');
      print(wrapWith('$observatoryUri', [cyan, styleUnderlined]));
      print(
          'For a more detailed help message, press "h". To quit, press "q".\n');

      if (_paths.isNotEmpty) {
        print(darkGray.wrap(
            'Changes to the following path(s) will also trigger a hot reload:'));

        for (var p in _paths) {
          print(darkGray.wrap('  * $p'));
        }

        stdout.writeln();
      }

      // Listen for hotkeys
      stdin.lineMode = stdin.echoMode = false;

      StreamSubscription<int> sub;
      sub = stdin.expand((l) => l).listen((ch) async {
        var ch = stdin.readByteSync();

        if (ch == $r) {
          _handleWatchEvent(
              new WatchEvent(ChangeType.MODIFY, '[manual-reload]'), isHot);
        }
        if (ch == $R) {
          //print('Manually restarting server...\n');
          _handleWatchEvent(
              new WatchEvent(ChangeType.MODIFY, '[manual-restart]'), false);
        } else if (ch == $q) {
          stdin.echoMode = stdin.lineMode = true;
          close();
          sub.cancel();
          exit(0);
        } else if (ch == $h) {
          print(
              'Press "r" to hot reload the Dart VM, and restart the active server.');
          print(
              'Press "R" to restart the server, WITHOUT a hot reload of the VM.');
          print('Press "q" to quit the server.');
          print('Press "h" to display this help information.');
          stdout.writeln();
        }
      });
    }

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
          if (uri != null)
            await _listenToStat(uri.toFilePath());
          else
            await _listenToStat(path.toFilePath());
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
        if (stat.type == FileSystemEntityType.link) {
          var lnk = new Link(path);
          var p = await lnk.resolveSymbolicLinks();
          return await _listenToStat(p);
        } else if (stat.type == FileSystemEntityType.file) {
          var file = new File(path);
          if (!await file.exists()) return null;
        } else if (stat.type == FileSystemEntityType.directory) {
          var dir = new Directory(path);
          if (!await dir.exists()) return null;
        } else
          return null;

        var watcher = new Watcher(path);

        watcher.events.listen(_onChange.add, onError: (e) {
          stderr.writeln('Could not listen to file changes at ${path}: $e');
        });

        // print('Listening for file changes at ${path}...');
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

  _handleWatchEvent(WatchEvent e, [bool hot = true]) async {
    print('${e.path} changed. Reloading server...\n');
    var old = _server;

    if (old != null) {
      // Do this asynchronously, because we really don't care about the old server anymore.
      new Future(() async {
        // Disconnect active WebSockets
        try {
          var ws = old.app.container.make<AngelWebSocket>();

          for (var client in ws.clients) {
            try {
              await client.close(WebSocketStatus.goingAway);
            } catch (e) {
              stderr.writeln(
                  'Couldn\'t close WebSocket from session #${client.request.session.id}: $e');
            }
          }

          await Future.forEach(old.app.shutdownHooks, old.app.configure);
        } catch (_) {
          // Fail silently...
        }
      });
    }

    _server = null;

    if (hot) {
      var report = await _client.reloadSources(_mainIsolate.id);

      if (!report.success) {
        stderr.writeln('Hot reload failed!!!');
        stderr.writeln(report.toString());
        exit(1);
      }
    }

    var s = await _generateServer();
    _server = s;
    while (!_requestQueue.isEmpty) await _handle(_requestQueue.removeFirst());
  }
}

/*
class _Debounce<S> extends StreamTransformerBase<S, S> {
  final Duration _delay;

  const _Debounce(this._delay);

  Stream<S> bind(Stream<S> stream) {
    var initial = new DateTime.now();
    var next = initial.subtract(this._delay);
    return stream.where((S data) {
      var now = new DateTime.now();
      if (now.isAfter(next)) {
        next = now.add(this._delay);
        return true;
      } else {
        return false;
      }
    });
  }
}
*/
