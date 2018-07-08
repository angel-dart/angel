part of angel_wings;

class AngelWings {
  static const int messageBegin = 0,
      messageComplete = 1,
      url = 2,
      headerField = 3,
      headerValue = 4,
      body = 5,
      upgrade = 6,
      upgradedMessage = 7;

  static const int DELETE = 0,
      GET = 1,
      HEAD = 2,
      POST = 3,
      PUT = 4,
      CONNECT = 5,
      OPTIONS = 6,
      TRACE = 7,
      COPY = 8,
      LOCK = 9,
      MKCOL = 10,
      MOVE = 11,
      PROPFIND = 12,
      PROPPATCH = 13,
      SEARCH = 14,
      UNLOCK = 15,
      BIND = 16,
      REBIND = 17,
      UNBIND = 18,
      ACL = 19,
      REPORT = 20,
      MKACTIVITY = 21,
      CHECKOUT = 22,
      MERGE = 23,
      MSEARCH = 24,
      NOTIFY = 25,
      SUBSCRIBE = 26,
      UNSUBSCRIBE = 27,
      PATCH = 28,
      PURGE = 29,
      MKCALENDAR = 30,
      LINK = 31,
      UNLINK = 32,
      SOURCE = 33;

  static String methodToString(int method) {
    switch (method) {
      case DELETE:
        return 'DELETE';
      case GET:
        return 'GET';
      case HEAD:
        return 'HEAD';
      case POST:
        return 'POST';
      case PUT:
        return 'PUT';
      case CONNECT:
        return 'CONNECT';
      case OPTIONS:
        return 'OPTIONS';
      case PATCH:
        return 'PATCH';
      case PURGE:
        return 'PURGE';
      default:
        throw new ArgumentError('Unknown method $method.');
    }
  }

  final Angel app;
  final bool shared;
  final bool useZone;

  final RawReceivePort _recv = new RawReceivePort();
  final Map<String, MockHttpSession> _sessions = {};
  final Map<int, WingsRequestContext> _staging = <int, WingsRequestContext>{};
  //final PooledMap<int, WingsRequestContext> _staging =
  //    new PooledMap<int, WingsRequestContext>();
  final Uuid _uuid = new Uuid();
  InternetAddress _address;
  int _port;
  SendPort _sendPort;

  static int _bindSocket(Uint8List address, String addressString, int port,
      int backlog, bool shared) native "BindSocket";

  static SendPort _startHttpListener() native "StartHttpListener";

  final Pool _pool = new Pool(1);

  static void __send(int sockfd, Uint8List data) native "Send";

  static void __closeSocket(int sockfd) native "CloseSocket";

  void _send(int sockfd, Uint8List data) {
    // _pool.withResource(() {
    print('Sending ${[sockfd, data]}');
    _sendPort.send([sockfd, data]);
    //});
    //_pool.withResource(() => __send(sockfd, data));
  }

  void _closeSocket(WingsRequestContext req) {
    //_pool.withResource(() {
    if (!req._closed) {
      req._closed = true;
      var sockfd = req._sockfd;
      print('Sending ${[sockfd]}');
      _sendPort.send([sockfd]);
    }
    //});
    //_pool.withResource(() => __closeSocket(sockfd));
  }

  AngelWings(this.app, {this.shared: false, this.useZone: true}) {
    _recv.handler = _handleMessage;
  }

  InternetAddress get address => _address;

  int get port => _port;

  Future startServer([host, int port, int backlog = 10]) {
    Future<InternetAddress> _addr = host is InternetAddress
        ? host
        : InternetAddress.lookup(host?.toString() ?? '127.0.0.1').then((list) =>
            list.isNotEmpty
                ? list.first
                : throw new StateError('IP lookup failed.'));

    return _addr.then((address) {
      try {
        var serverInfoIndex = _bindSocket(
            new Uint8List.fromList(address.rawAddress),
            address.address,
            port ?? 0,
            backlog,
            shared);
        _sendPort = _startHttpListener();
        _sendPort.send([_recv.sendPort, serverInfoIndex]);
        _address = address;
        _port = port;
      } on List catch (osError) {
        if (osError.length == 3) {
          throw new SocketException(osError[0] as String,
              osError: new OSError(osError[1] as String, osError[2] as int));
        } else {
          throw new SocketException('Could not start Wings server.',
              osError: new OSError(osError[0] as String, osError[1] as int));
        }
      } on String catch (message) {
        throw new SocketException(message);
      }
    });
  }

  Future close() {
    _sendPort.send([true, _sendPort]);
    _recv.close();
    return new Future.value();
  }

  void _handleMessage(x) {
    print('INPUT: $x');
    if (x is String) {
      close();
      throw new StateError(x);
    } else if (x is List && x.length >= 2) {
      int sockfd = x[0], command = x[1];

      //WingsRequestContext _newRequest() =>
      //    new WingsRequestContext._(this, sockfd, app);
      //print(x);

      switch (command) {
        case messageBegin:
          print('BEGIN $sockfd');
          _staging[sockfd] = new WingsRequestContext._(this, sockfd, app);
          break;
        case messageComplete:
          print('$sockfd in $_staging???');
          var rq = _staging.remove(sockfd);
          if (rq != null) {
            rq._method = methodToString(x[2] as int);
            rq._addressBytes = x[5] as Uint8List;
            _handleRequest(rq);
          }
          break;
        case body:
          var rq = _staging[sockfd];
          if (rq != null) {
            (rq._body ??= new StreamController<Uint8List>())
                .add(x[2] as Uint8List);
          }
          break;
        //case upgrade:
        // TODO: Handle WebSockets...?
        //  if (onUpgrade != null) onUpgrade(sockfd);
        //  break;
        //case upgradedMessage:
        // TODO: Handle upgrade
        //  onUpgradedMessage(sockfd, x[2]);
        //  break;
        case url:
          _staging[sockfd]?.__url = x[2] as String;
          break;
        case headerField:
          _staging[sockfd]?._headerField = x[2] as String;
          break;
        case headerValue:
          _staging[sockfd]?._headerValue = x[2] as String;
          break;
      }
    }
  }

  Future _handleRequest(WingsRequestContext req) {
    print('req: $req');
    if (req == null) return new Future.value();
    var res = new WingsResponseContext._(req)
      ..app = app
      ..serializer = (app.serializer ?? god.serialize)
      ..encoders.addAll(app.encoders);
    print('Handling fd: ${req._sockfd}');

    handle() {
      var path = req.path;
      if (path == '/') path = '';

      Tuple3<List, Map, ParseResult<Map<String, dynamic>>> resolveTuple() {
        Router r = app.optimizedRouter;
        var resolved =
            r.resolveAbsolute(path, method: req.method, strip: false);

        return new Tuple3(
          new MiddlewarePipeline(resolved).handlers,
          resolved.fold<Map>({}, (out, r) => out..addAll(r.allParams)),
          resolved.isEmpty ? null : resolved.first.parseResult,
        );
      }

      var cacheKey = req.method + path;
      var tuple = app.isProduction
          ? app.handlerCache.putIfAbsent(cacheKey, resolveTuple)
          : resolveTuple();

      req.params.addAll(tuple.item2);
      req.inject(ParseResult, tuple.item3);

      if (!app.isProduction && app.logger != null)
        req.inject(Stopwatch, new Stopwatch()..start());

      var pipeline = tuple.item1;

      Future<bool> Function() runPipeline;

      print('Pipeline: $pipeline');
      for (var handler in pipeline) {
        if (handler == null) break;

        if (runPipeline == null)
          runPipeline = () => app.executeHandler(handler, req, res);
        else {
          var current = runPipeline;
          runPipeline = () => current().then((result) => !result
              ? new Future.value(result)
              : app.executeHandler(handler, req, res));
        }
      }

      return runPipeline == null
          ? sendResponse(req, res)
          : runPipeline().then((_) => sendResponse(req, res));
    }

    if (useZone == false) {
      return handle().catchError((e, StackTrace st) {
        if (e is FormatException)
          throw new AngelHttpException.badRequest(message: e.message)
            ..stackTrace = st;
        throw new AngelHttpException(e, stackTrace: st, statusCode: 500);
      }, test: (e) => e is! AngelHttpException).catchError(
          (AngelHttpException e, StackTrace st) {
        return handleAngelHttpException(e, e.stackTrace ?? st, req, res);
      }).whenComplete(() => res.dispose());
    } else {
      var zoneSpec = new ZoneSpecification(
        print: (self, parent, zone, line) {
          if (app.logger != null)
            app.logger.info(line);
          else
            parent.print(zone, line);
        },
        handleUncaughtError: (self, parent, zone, error, stackTrace) {
          var trace = new Trace.from(stackTrace ?? StackTrace.current).terse;

          return new Future(() {
            AngelHttpException e;

            if (error is FormatException) {
              e = new AngelHttpException.badRequest(message: error.message);
            } else if (error is AngelHttpException) {
              e = error;
            } else {
              e = new AngelHttpException(error,
                  stackTrace: stackTrace, message: error?.toString());
            }

            if (app.logger != null) {
              app.logger.severe(e.message ?? e.toString(), error, trace);
            }

            return handleAngelHttpException(e, trace, req, res);
          }).catchError((e, StackTrace st) {
            var trace = new Trace.from(st ?? StackTrace.current).terse;
            _closeSocket(req);
            // Ideally, we won't be in a position where an absolutely fatal error occurs,
            // but if so, we'll need to log it.
            if (app.logger != null) {
              app.logger.severe(
                  'Fatal error occurred when processing ${req.uri}.', e, trace);
            } else {
              stderr
                ..writeln('Fatal error occurred when processing '
                    '${req.uri}:')
                ..writeln(e)
                ..writeln(trace);
            }
          });
        },
      );

      var zone = Zone.current.fork(specification: zoneSpec);
      req.inject(Zone, zone);
      req.inject(ZoneSpecification, zoneSpec);
      return zone.run(handle).whenComplete(() {
        res.dispose();
      });
    }
  }

  /// Handles an [AngelHttpException].
  Future handleAngelHttpException(AngelHttpException e, StackTrace st,
      WingsRequestContext req, WingsResponseContext res,
      {bool ignoreFinalizers: false}) {
    if (req == null || res == null) {
      try {
        app.logger?.severe(e, st);
        var b = new StringBuffer();
        b.writeln('HTTP/1.1 500 Internal Server Error');
        b.writeln();

        _send(req._sockfd, _coerceUint8List(b.toString().codeUnits));
        _closeSocket(req);
      } finally {
        return null;
      }
    }

    Future handleError;

    if (!res.isOpen)
      handleError = new Future.value();
    else {
      res.statusCode = e.statusCode;
      handleError =
          new Future.sync(() => app.errorHandler(e, req, res)).then((result) {
        return app.executeHandler(result, req, res).then((_) => res.end());
      });
    }

    return handleError.then((_) =>
        sendResponse(req, res, ignoreFinalizers: ignoreFinalizers == true));
  }

  /// Sends a response.
  Future sendResponse(WingsRequestContext req, WingsResponseContext res,
      {bool ignoreFinalizers: false}) {
    print('Closing: ${req._sockfd}');
    if (res.willCloseItself) return new Future.value();
    print('Not self-closing: ${req._sockfd}');

    Future finalizers = ignoreFinalizers == true
        ? new Future.value()
        : app.responseFinalizers.fold<Future>(
            new Future.value(), (out, f) => out.then((_) => f(req, res)));

    if (res.isOpen) res.end();

    var headers = <String, String>{};
    headers.addAll(res.headers);

    headers['content-length'] = res.buffer.length.toString();

    // Ignore chunked transfer encoding
    //request.response.headers.chunkedTransferEncoding = res.chunked ?? true;
    // TODO: Is there a need to support this?

    print('Buffer: ${res.buffer}');
    List<int> outputBuffer = res.buffer.toBytes();

    if (res.encoders.isNotEmpty) {
      var allowedEncodings = req.headers
          .value('accept-encoding')
          ?.split(',')
          ?.map((s) => s.trim())
          ?.where((s) => s.isNotEmpty)
          ?.map((str) {
        // Ignore quality specifications in accept-encoding
        // ex. gzip;q=0.8
        if (!str.contains(';')) return str;
        return str.split(';')[0];
      });

      if (allowedEncodings != null) {
        for (var encodingName in allowedEncodings) {
          Converter<List<int>, List<int>> encoder;
          String key = encodingName;

          if (res.encoders.containsKey(encodingName))
            encoder = res.encoders[encodingName];
          else if (encodingName == '*') {
            encoder = res.encoders[key = res.encoders.keys.first];
          }

          if (encoder != null) {
            headers['content-encoding'] = key;
            outputBuffer = res.encoders[key].convert(outputBuffer);

            headers['content-length'] = outputBuffer.length.toString();
            break;
          }
        }
      }
    }

    print('Create string buffer');
    var b = new StringBuffer();
    b.writeln('HTTP/1.1 ${res.statusCode}');

    res.headers.forEach((k, v) {
      b.writeln('$k: $v');
    });

    // Persist session ID
    if (res.correspondingRequest._session != null) {
      res.cookies
          .add(new Cookie('DARTSESSID', res.correspondingRequest._session.id));
    }

    // Send all cookies
    for (var cookie in res.cookies) {
      var value = cookie.toString();
      b.writeln('set-cookie: $value');
    }

    b.writeln();
    print(b);

    var bb = new BytesBuilder(copy: false)
      ..add(b.toString().codeUnits)
      ..add(outputBuffer);
    var buf = _coerceUint8List(bb.takeBytes());
    print('Output: $buf');

    return finalizers.then((_) {
      print('A');
      _send(req._sockfd, buf);
      print('B');
      _closeSocket(req);
      print('C');

      if (req.injections.containsKey(PoolResource)) {
        req.injections[PoolResource].release();
      }

      if (!app.isProduction && app.logger != null) {
        var sw = req.grab<Stopwatch>(Stopwatch);

        if (sw.isRunning) {
          sw?.stop();
          app.logger.info("${res.statusCode} ${req.method} ${req.uri} (${sw
                ?.elapsedMilliseconds ?? 'unknown'} ms)");
        }
      }
    });
  }
}
