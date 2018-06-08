import 'dart:async';
import 'dart:io';
import '../core/core.dart';
import '../http/http.dart';
import 'stats.dart';

@deprecated
class AngelMetrics extends Angel {
  Angel _inner;
  StreamSubscription<HttpRequest> _sub;

  AngelMetrics() : super() {
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

  final AngelMetricsStats stats = new AngelMetricsStats._();

  @override
  Future<HttpServer> close()  {
    _sub?.cancel();
      _inner.close();
    return   super.close();
  }

  @override
  Iterable<RoutingResult> resolveAll(String absolute, String relative,
      {String method: 'GET', bool strip: true}) {
    return stats.resolveAll.run(() =>
        _inner.resolveAll(absolute, relative, method: method, strip: strip));
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
}

class AngelMetricsStats {
  AngelMetricsStats._() {
    all = [
      resolveAll,
      executeHandler,
      getHandlerResult,
      runContained,
    ];
  }

  final Stats resolveAll = new Stats('resolveAll');
  final Stats executeHandler = new Stats('executeHandler');
  final Stats getHandlerResult = new Stats('getHandlerResult');
  final Stats runContained = new Stats('runContained');

  List<Stats> all;

  void add(Stats stats) {
    all.add(stats);
  }

  void log() {
    all.forEach((s) => s.log());
  }
}
