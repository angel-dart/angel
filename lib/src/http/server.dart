part of angel_framework.http;

/// A function that binds an [Angel] server to an Internet address and port.
typedef Future<HttpServer> ServerGenerator(InternetAddress address, int port);

/// A function that configures an [Angel] server in some way.
typedef AngelConfigurer(Angel app);

/// A powerful real-time/REST/MVC server class.
class Angel extends Routable {
  ServerGenerator _serverGenerator = (address, port) async => await HttpServer
      .bind(address, port);
  var viewGenerator = (String view, {Map data}) => {};

  HttpServer httpServer;
  God god = new God();

  /// A set of custom properties that can be assigned to the server.
  ///
  /// Useful for configuration and extension.
  Map properties = {};

  startServer(InternetAddress address, int port) async {
    var server = await _serverGenerator(
        address ?? InternetAddress.LOOPBACK_IP_V4, port);
    this.httpServer = server;
    var router = new Router(server);

    this.routes.forEach((Route route) {
      router.serve(route.matcher, method: route.method).listen((
          HttpRequest request) async {
        RequestContext req = await RequestContext.from(
            request, route.parseParameters(request.uri.toString()), this,
            route);
        ResponseContext res = await ResponseContext.from(
            request.response, this);
        bool canContinue = true;

        for (var handler in route.handlers) {
          if (canContinue) {
            canContinue = await new Future<bool>.sync(() async {
              return _applyHandler(handler, req, res);
            }).catchError((e) {
              stderr.write(e.error);
              canContinue = false;
              return false;
            });
          }
        }

        if (!res.willCloseItself) {
          res.responseData.forEach((blob) => request.response.add(blob));
          await request.response.close();
        }
      });
    });

    return server;
  }

  Future<bool> _applyHandler(handler, RequestContext req,
      ResponseContext res) async {
    if (handler is Middleware) {
      return await handler(req, res);
    }

    else if (handler is RequestHandler) {
      await handler(req, res);
      return res.isOpen;
    }

    else if (handler is RawRequestHandler) {
      var result = await handler(req.underlyingRequest);
      return result is bool && result == true;
    }

    else if (handler is Function || handler is Future) {
      var result = await handler();
      return result is bool && result == true;
    }

    else if (middleware.containsKey(handler)) {
      return await _applyHandler(middleware[handler], req, res);
    }

    else {
      res.willCloseItself = true;
      res.underlyingResponse.write(god.serialize(handler));
      await res.underlyingResponse.close();
      return false;
    }
  }

  /// Applies an [AngelConfigurer] to this instance.
  void configure(AngelConfigurer configurer) {
    configurer(this);
  }

  /// Starts the server.
  void listen({InternetAddress address, int port: 3000}) {
    runZoned(() async {
      await startServer(address, port);
    }, onError: onError);
  }

  /// Handles a server error.
  var onError = (e, [StackTrace stackTrace]) {
    stderr.write(e.toString());
    if (stackTrace != null)
      stderr.write(stackTrace.toString());
  };

  Angel() : super() {}

  /// Creates an HTTPS server.
  Angel.secure() : super() {}

  noSuchMethod(Invocation invocation) {
    if (invocation.memberName != null) {
      String name = MirrorSystem.getName(invocation.memberName);
      if (properties.containsKey(name)) {
        if (invocation.isGetter)
          return properties[name];
        else if (invocation.isMethod) {
          return Function.apply(
              properties[name], invocation.positionalArguments,
              invocation.namedArguments);
        }
      }
    }

    super.noSuchMethod(invocation);
  }


}