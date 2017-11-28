import 'dart:async';
import 'dart:io';
import '../http/http.dart';
import 'stats.dart';

/// A variant of an [Angel] server that records performance metrics.
class AngelMetrics extends Angel {
  Angel _inner;
  HttpServer _server;
  StreamSubscription<HttpRequest> _sub;

  AngelMetrics() : super() {
    var zoneBuilder = createZoneForRequest;
    createZoneForRequest = (request, req, res) async {
      var spec = await zoneBuilder(request, req, res);
      return new ZoneSpecification.from(
        spec,
      );
    };

    get('/metrics', (req, res) {
      res.contentType = ContentType.HTML;

      var rows = stats.all.map((stat) {
        return '''
          <tr>
              <td>${stat.name}</td>
              <td>${stat.iterations}</td>
              <td>${stat.sum}ms</td>
              <td>${stat.average.toStringAsFixed(2)}ms</td>
            </tr>''';
      }).join();

      res.write('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Metrics</title>
          </head>
          <body>
            <h1>Metrics</h1>
            <i>Updated every 5 seconds</i>
            <table>
              <thead>
                <tr>
                  <th>Stat</th>
                  <th># Iterations</th>
                  <th>Total (ms)</th>
                  <th>Average (ms)</th>
                </tr>
              </thead>
              <tbody>$rows</tbody>
            </table>
            <script>
              window.setTimeout(function() {
                window.location.reload();
              }, 5000);
            </script>
          </body>
        </html>
        ''');
    });
  }

  factory AngelMetrics.custom(ServerGenerator serverGenerator) {
    return new AngelMetrics().._inner = new Angel.custom(serverGenerator);
  }

  @override
  HttpServer get httpServer => _server ?? super.httpServer;

  final AngelMetricsStats stats = new AngelMetricsStats._();

  @override
  Future<HttpServer> startServer([address, int port]) async {
    if (_inner == null) return await super.startServer(address, port);

    var host = address ?? InternetAddress.LOOPBACK_IP_V4;
    _server = await _inner.serverGenerator(host, port ?? 0);

    for (var configurer in startupHooks) {
      await configure(configurer);
    }

    optimizeForProduction();
    _sub = _server.listen(handleRequest);
    return _server;
  }

  @override
  Future<HttpServer> close() async {
    _sub?.cancel();
    await _inner.close();
    return await super.close();
  }

  @override
  Future<RequestContext> createRequestContext(HttpRequest request) {
    return stats.createRequestContext
        .run<RequestContext>(() => super.createRequestContext(request));
  }

  @override
  Future<ResponseContext> createResponseContext(HttpResponse response,
      [RequestContext correspondingRequest]) {
    return stats.createResponseContext.run<ResponseContext>(
        () => super.createResponseContext(response, correspondingRequest));
  }

  @override
  Iterable<RoutingResult> resolveAll(String absolute, String relative,
      {String method: 'GET', bool strip: true}) {
    return stats.resolveAll
        .run(() => super.resolveAll(absolute, relative, method: method, strip: strip));
  }

  @override
  Future handleRequest(HttpRequest request) {
    return stats.handleRequest.run(() async {
      await super.handleRequest(request);
    });
  }

  @override
  Future<bool> executeHandler(
      handler, RequestContext req, ResponseContext res) {
    return stats.executeHandler
        .run<bool>(() => super.executeHandler(handler, req, res));
  }

  @override
  Future getHandlerResult(handler, RequestContext req, ResponseContext res) {
    return stats.getHandlerResult
        .run(() => super.getHandlerResult(handler, req, res));
  }

  @override
  Future runContained(
      Function handler, RequestContext req, ResponseContext res) {
    return stats.runContained.run(() => super.runContained(handler, req, res));
  }

  @override
  Future sendResponse(
      HttpRequest request, RequestContext req, ResponseContext res,
      {bool ignoreFinalizers: false}) {
    return stats.sendResponse.run(() => super.sendResponse(request, req, res));
  }
}

class AngelMetricsStats {
  AngelMetricsStats._() {
    all = [
      createRequestContext,
      createResponseContext,
      resolveAll,
      executeHandler,
      getHandlerResult,
      runContained,
      sendResponse,
      handleRequest,
    ];
  }

  final Stats createRequestContext = new Stats('createRequestContext');
  final Stats createResponseContext = new Stats('createResponseContext');
  final Stats resolveAll = new Stats('resolveAll');
  final Stats handleRequest = new Stats('handleRequest');
  final Stats executeHandler = new Stats('executeHandler');
  final Stats getHandlerResult = new Stats('getHandlerResult');
  final Stats runContained = new Stats('runContained');
  final Stats sendResponse = new Stats('sendResponse');

  List<Stats> all;

  void add(Stats stats) {
    all.add(stats);
  }

  void log() {
    all.forEach((s) => s.log());
  }
}
