import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

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

class ProxyLayer {
  HttpClient _client;
  String _prefix;
  final bool debug;
  final String host, mapTo, publicPath;
  final int port;

  ProxyLayer(this.host, this.port,
      {this.debug: false,
      this.mapTo: '/',
      this.publicPath: '/',
      SecurityContext securityContext}) {
    _client = new HttpClient(context: securityContext);
    _prefix = publicPath.replaceAll(_straySlashes, '');
  }

  call(AngelBase app) async => serve(app);

  _printDebug(msg) {
    if (debug == true) print(msg);
  }

  void close() => _client.close(force: true);

  void serve(Router router) {
    _printDebug('Public path prefix: "$_prefix"');

    handler(RequestContext req, ResponseContext res) async {
      var path = req.path.replaceAll(_straySlashes, '');

      return serveFile(path, req, res);
    }

    router.get('$publicPath/*', handler);
    router.get(publicPath, (req, res) => serveFile('', req, res));
  }

  serveFile(String path, RequestContext req, ResponseContext res) async {
    var _path = path;

    if (_prefix.isNotEmpty) {
      _path = path.replaceAll(new RegExp('^' + _pathify(_prefix)), '');
    }

    res
      ..willCloseItself = true
      ..end();

    // Create mapping
    final mapping = '$mapTo/$_path'.replaceAll(_straySlashes, '');
    final rq = await _client.open(req.method, host, port, mapping);
    await rq.addStream(req.io);
    final HttpClientResponse rs = await rq.close();
    final HttpResponse r = res.io;
    r.statusCode = rs.statusCode;
    r.headers.contentType = rs.headers.contentType;
    await r.addStream(rs);
    await r.flush();
    await r.close();
  }
}
