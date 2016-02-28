part of angel_framework.http;

/// A function that binds
typedef Future<HttpServer> ServerGenerator(InternetAddress address, int port);

/// A powerful real-time/REST/MVC server class.
class Angel extends Routable {
  ServerGenerator _serverGenerator;

  _startServer(InternetAddress address, int port) async {
    var server = await _serverGenerator(
        address ?? InternetAddress.LOOPBACK_IP_V4, port);
    var router = new Router(server);

    this.routes.forEach((Route route, value) {
      router.serve(route.matcher, method: route.method).listen((
          HttpRequest request) {

      });
    });
  }

  /// Starts the server.
  void listen({InternetAddress address, int port: 3000}) {
    runZoned(() async {
      await _startServer(address, port);
    }, onError: onError);
  }

  /// Handles a server error.
  void onError(e, [StackTrace stackTrace]) {

  }

  Angel() {}

  /// Creates an HTTPS server.
  Angel.secure() {}
}