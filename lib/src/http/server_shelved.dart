part of angel_framework.http.server;


// Todo: Shelf interop
class ShelvedAngel extends Angel {
  shelf.Pipeline pipeline = new shelf.Pipeline();

  ShelvedAngel({bool debug: false}) : super(debug: debug) {}

  @override
  Future<HttpServer> startServer([InternetAddress address, int port]) async {
    /* final handler = pipeline.addHandler((shelf.Request req) {
      // io.handleRequest()
    });*/

    return await super.startServer(address, port);
  }

}
