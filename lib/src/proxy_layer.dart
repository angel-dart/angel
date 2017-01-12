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

/// Copies HTTP headers ;)
void copyHeaders(HttpHeaders from, HttpHeaders to) {
  from.forEach(to.set);

  /*to
    ..chunkedTransferEncoding = from.chunkedTransferEncoding
    ..contentLength = from.contentLength
    ..contentType = from.contentType
    ..date = from.date
    ..expires = from.expires
    ..host = from.host
    ..ifModifiedSince = from.ifModifiedSince
    ..persistentConnection = from.persistentConnection
    ..port = from.port;*/
}

class ProxyLayer {
  HttpClient _client;
  String _prefix;
  final bool debug;
  final String host, mapTo, publicPath;
  final int port;
  final String protocol;

  ProxyLayer(this.host, this.port,
      {this.debug: false,
      this.mapTo: '/',
      this.publicPath: '/',
      this.protocol: 'http',
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
    _printDebug('Serving path $_path via proxy');
    final mapping = '$mapTo/$_path'.replaceAll(_straySlashes, '');
    _printDebug('Mapped path $_path to path $mapping on proxy $host:$port');
    final rq = await _client.open(req.method, host, port, mapping);
    _printDebug('Opened client request');

    copyHeaders(req.headers, rq.headers);
    _printDebug('Copied headers');
    rq.cookies.addAll(req.cookies ?? []);
    _printDebug('Added cookies');
    rq.headers
        .set('X-Forwarded-For', req.io.connectionInfo.remoteAddress.address);
    rq.headers
      ..set('X-Forwarded-Port', req.io.connectionInfo.remotePort.toString())
      ..set('X-Forwarded-Host',
          req.headers.host ?? req.headers.value(HttpHeaders.HOST) ?? 'none')
      ..set('X-Forwarded-Proto', protocol);
    _printDebug('Added X-Forwarded headers');

    await rq.addStream(req.io);
    final HttpClientResponse rs = await rq.close();
    final HttpResponse r = res.io;
    _printDebug(
        'Proxy responded to $mapping with status code ${rs.statusCode}');
    r.statusCode = rs.statusCode;
    r.headers.contentType = rs.headers.contentType;
    copyHeaders(rs.headers, r.headers);
    await r.addStream(rs);
    await r.flush();
    await r.close();
  }
}
