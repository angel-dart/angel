part of angel_framework.http;

/// A function that binds an [Angel] server to an Internet address and port.
typedef Future<HttpServer> ServerGenerator(InternetAddress address, int port);

/// Handles an [AngelHttpException].
typedef Future AngelErrorHandler(
    AngelHttpException err, RequestContext req, ResponseContext res);

/// A function that configures an [Angel] server in some way.
typedef Future AngelConfigurer(Angel app);

/// A powerful real-time/REST/MVC server class.
class Angel extends Routable {
  ServerGenerator _serverGenerator =
      (address, port) async => await HttpServer.bind(address, port);

  /// Default error handler, show HTML error page
  AngelErrorHandler _errorHandler = (AngelHttpException e, req, ResponseContext res) {
    res.header(HttpHeaders.CONTENT_TYPE, ContentType.HTML.toString());
    res.status(e.statusCode);
    res.write("<!DOCTYPE html><html><head><title>${e.message}</title>");
    res.write("</head><body><h1>${e.message}</h1><ul>");
    for (String error in e.errors) {
      res.write("<li>$error</li>");
    }
    res.write("</ul></body></html>");
    res.end();
  };

  /// A function that renders views.
  ///
  /// Called by [ResponseContext]@`render`.
  ViewGenerator viewGenerator = (String view, [Map data]) async => "No view engine has been configured yet.";

  /// [RequestMiddleware] to be run before all requests.
  List before = [];

  /// [RequestMiddleware] to be run after all requests.
  List after = [];

  /// The native HttpServer running this instancce.
  HttpServer httpServer;

  /// Starts the server.
  ///
  /// Returns false on failure; otherwise, returns the HttpServer.
  startServer(InternetAddress address, int port) async {
    var server =
        await _serverGenerator(address ?? InternetAddress.LOOPBACK_IP_V4, port);
    this.httpServer = server;

    server.listen((HttpRequest request) async {
      String req_url =
          request.uri.toString().replaceAll("?" + request.uri.query, "").replaceAll(new RegExp(r'\/+$'), '');
      if (req_url.isEmpty) req_url = '/';
      RequestContext req = await RequestContext.from(request, {}, this, null);
      ResponseContext res = await ResponseContext.from(request.response, this);

      bool canContinue = true;

      var execHandler = (handler, req) async {
        if (canContinue) {
          canContinue = await new Future.sync(() async {
            return _applyHandler(handler, req, res);
          }).catchError((e, [StackTrace stackTrace]) async {
            if (e is AngelHttpException) {
              // Special handling for AngelHttpExceptions :)
              try {
                res.status(e.statusCode);
                String accept = request.headers.value(HttpHeaders.ACCEPT);
                if (accept == "*/*" ||
                    accept.contains("application/json") ||
                    accept.contains("application/javascript")) {
                  res.json(e.toMap());
                } else {
                  await _errorHandler(e, req, res);
                }
                _finalizeResponse(request, res);
              } catch (_) {}
            }
            _onError(e, stackTrace);
            canContinue = false;
            return false;
          });
        } else
          return false;
      };

      for (var handler in before) {
        await execHandler(handler, req);
      }

      for (Route route in routes) {
        if (!canContinue) break;
        if (route.matcher.hasMatch(req_url) &&
            (request.method == route.method || route.method == '*')) {
          req.params = route.parseParameters(req_url);
          req.route = route;

          for (var handler in route.handlers) {
            await execHandler(handler, req);
          }
        }
      }

      for (var handler in after) {
        await execHandler(handler, req);
      }
      _finalizeResponse(request, res);
    });

    return server;
  }

  Future<bool> _applyHandler(
      handler, RequestContext req, ResponseContext res) async {
    if (handler is RequestMiddleware) {
      var result = await handler(req, res);
      if (result is bool)
        return result == true;
      else if (result != null) {
        res.json(result);
        return false;
      } else
        return res.isOpen;
    }

    if (handler is RequestHandler) {
      await handler(req, res);
      return res.isOpen;
    } else if (handler is RawRequestHandler) {
      var result = await handler(req.underlyingRequest);
      if (result is bool)
        return result == true;
      else if (result != null) {
        res.json(result);
        return false;
      } else
        return true;
    } else if (handler is Function || handler is Future) {
      var result = await handler();
      if (result is bool)
        return result == true;
      else if (result != null) {
        res.json(result);
        return false;
      } else
        return true;
    } else if (requestMiddleware.containsKey(handler)) {
      return await _applyHandler(requestMiddleware[handler], req, res);
    } else {
      res.willCloseItself = true;
      res.underlyingResponse.write(god.serialize(handler));
      await res.underlyingResponse.close();
      return false;
    }
  }

  _finalizeResponse(HttpRequest request, ResponseContext res) async {
    try {
      if (!res.willCloseItself) {
        res.responseData.forEach((blob) => request.response.add(blob));
        await request.response.close();
      }
    } catch (e) {
      // Remember: This fails silently
    }
  }

  String _randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      return rand.nextInt(33) + 89;
    });

    return new String.fromCharCodes(codeUnits);
  }

  /// Applies an [AngelConfigurer] to this instance.
  Future configure(AngelConfigurer configurer) async {
    await configurer(this);
  }

  /// Starts the server.
  void listen({InternetAddress address, int port: 3000}) {
    runZoned(() async {
      await startServer(address, port);
    }, onError: _onError);
  }

  @override
  use(Pattern path, Routable routable,
      {bool hooked: true, String middlewareNamespace: null}) {
    if (routable is Service) {
      routable.app = this;
    }
    return super.use(path, routable,
        hooked: hooked, middlewareNamespace: middlewareNamespace);
  }

  /// Registers a callback to run upon errors.
  onError(AngelErrorHandler handler) {
    _errorHandler = handler;
  }

  /// Handles a server error.
  _onError(e, [StackTrace stackTrace]) {
    stderr.write(e.toString());
    if (stackTrace != null) stderr.write(stackTrace.toString());
  }

  Angel() : super() {}

  /// Creates an HTTPS server.
  /// Provide paths to a certificate chain and server key (both .pem).
  /// If no password is provided, a random one will be generated upon running
  /// the server.
  Angel.secure(String certificateChainPath, String serverKeyPath,
      {String password})
      : super() {
    _serverGenerator = (InternetAddress address, int port) async {
      var certificateChain =
          Platform.script.resolve('server_chain.pem').toFilePath();
      var serverKey = Platform.script.resolve('server_key.pem').toFilePath();
      var serverContext = new SecurityContext();
      serverContext.useCertificateChain(certificateChain);
      serverContext.usePrivateKey(serverKey,
          password: password ?? _randomString(8));

      return await HttpServer.bindSecure(address, port, serverContext);
    };
  }
}
