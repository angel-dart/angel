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
  to
    ..chunkedTransferEncoding = from.chunkedTransferEncoding
    ..contentLength = from.contentLength
    ..contentType = from.contentType
    ..date = from.date
    ..expires = from.expires
    ..host = from.host
    ..ifModifiedSince = from.ifModifiedSince
    ..persistentConnection = from.persistentConnection
    ..port = from.port;

  from.forEach((header, values) {
    to.set(header, values);
  });
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
    final mapping = '$mapTo/$_path'.replaceAll(_straySlashes, '');
    final rq = await _client.open(req.method, host, port, mapping);

    if (req.headers.contentType != null)
      rq.headers.contentType = req.headers.contentType;

    rq.cookies.addAll(req.cookies);
    copyHeaders(req.headers, rq.headers);

    if (req.headers[HttpHeaders.ACCEPT] == null) {
      req.headers.set(HttpHeaders.ACCEPT, '*/*');
    }

    rq.headers
      ..add('X-Forwarded-For', req.connectionInfo.remoteAddress.address)
      ..add('X-Forwarded-Port', req.connectionInfo.remotePort.toString())
      ..add('X-Forwarded-Host',
          req.headers.host ?? req.headers.value(HttpHeaders.HOST) ?? 'none')
      ..add('X-Forwarded-Proto', protocol);

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
