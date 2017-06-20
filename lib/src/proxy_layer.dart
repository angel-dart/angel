import 'dart:async';
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
  from.forEach((k, v) {
    if (k != HttpHeaders.SERVER &&
        (k != HttpHeaders.CONTENT_ENCODING || !v.contains('gzip')))
      to.set(k, v);
  });

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
  Angel app;
  HttpClient _client;
  String _prefix;

  /// If `true` (default), then the plug-in will ignore failures to connect to the proxy, and allow other handlers to run.
  final bool recoverFromDead;
  final bool debug, recoverFrom404, streamToIO;
  final String host, mapTo, publicPath;
  final int port;
  final String protocol;
  final Duration timeout;

  ProxyLayer(
    this.host,
    this.port, {
    this.debug: false,
    this.mapTo: '/',
    this.publicPath: '/',
    this.protocol: 'http',
    this.recoverFromDead: true,
    this.recoverFrom404: true,
    this.streamToIO: false,
    this.timeout,
    SecurityContext securityContext,
  }) {
    _client = new HttpClient(context: securityContext);
    _prefix = publicPath.replaceAll(_straySlashes, '');
  }

  call(Angel app) async => serve(this.app = app);

  void close() => _client.close(force: true);

  void serve(Router router) {
    // _printDebug('Public path prefix: "$_prefix"');

    handler(RequestContext req, ResponseContext res) async {
      var path = req.path.replaceAll(_straySlashes, '');
      return serveFile(path, req, res);
    }

    router.all('$publicPath/*', handler);
  }

  serveFile(String path, RequestContext req, ResponseContext res) async {
    var _path = path;
    HttpClientResponse rs;

    if (_prefix.isNotEmpty) {
      _path = path.replaceAll(new RegExp('^' + _pathify(_prefix)), '');
    }

    // Create mapping
    // _printDebug('Serving path $_path via proxy');
    final mapping = '$mapTo/$_path'.replaceAll(_straySlashes, '');
    // _printDebug('Mapped path $_path to path $mapping on proxy $host:$port');

    try {
      Future<HttpClientResponse> accessRemote() async {
        var ips = await InternetAddress.lookup(host);
        if (ips.isEmpty)
          throw new StateError('Could not resolve remote host "$host".');
        var address = ips.first.address;
        final rq = await _client.open(req.method, address, port, mapping);
        // _printDebug('Opened client request at "$address:$port/$mapping"');

        copyHeaders(req.headers, rq.headers);
        rq.headers.set(HttpHeaders.HOST, host);
        // _printDebug('Copied headers');
        rq.cookies.addAll(req.cookies ?? []);
        // _printDebug('Added cookies');
        rq.headers.set(
            'X-Forwarded-For', req.io.connectionInfo.remoteAddress.address);
        rq.headers
          ..set('X-Forwarded-Port', req.io.connectionInfo.remotePort.toString())
          ..set('X-Forwarded-Host',
              req.headers.host ?? req.headers.value(HttpHeaders.HOST) ?? 'none')
          ..set('X-Forwarded-Proto', protocol);
        // _printDebug('Added X-Forwarded headers');

        if (app.storeOriginalBuffer == true) {
          await req.parse();
          if (req.originalBuffer?.isNotEmpty == true)
            rq.add(req.originalBuffer);
        }

        await rq.flush();
        return await rq.close();
      }

      var future = accessRemote();
      if (timeout != null) future = future.timeout(timeout);
      rs = await future;
    } on TimeoutException catch (e, st) {
      if (recoverFromDead != false)
        return true;
      else
        throw new AngelHttpException(e,
            stackTrace: st,
            statusCode: HttpStatus.GATEWAY_TIMEOUT,
            message:
                'Connection to remote host "$host" timed out after ${timeout.inMilliseconds}ms.');
    } catch (e) {
      if (recoverFromDead != false)
        return true;
      else
        rethrow;
    }

    // _printDebug(
    //    'Proxy responded to $mapping with status code ${rs.statusCode}');

    if (rs.statusCode == 404 && recoverFrom404 != false) return true;

    res
      ..statusCode = rs.statusCode
      ..contentType = rs.headers.contentType;

    // _printDebug('Proxy response headers:\n${rs.headers}');

    if (streamToIO == true) {
      res
        ..willCloseItself = true
        ..end();

      copyHeaders(rs.headers, res.io.headers);
      res.io.statusCode = rs.statusCode;

      if (rs.headers.contentType != null)
        res.io.headers.contentType = rs.headers.contentType;

      // _printDebug('Outgoing content length: ${res.io.contentLength}');

      if (rs.headers[HttpHeaders.CONTENT_ENCODING]?.contains('gzip') == true) {
        res.io.headers.set(HttpHeaders.CONTENT_ENCODING, 'gzip');
        await rs.transform(GZIP.encoder).pipe(res.io);
      } else
        await rs.pipe(res.io);
    } else {
      rs.headers.forEach((k, v) {
        if (k != HttpHeaders.CONTENT_ENCODING || !v.contains('gzip'))
          res.headers[k] = v.join(',');
      });

      await rs.forEach(res.buffer.add);
    }

    return res.buffer.isEmpty;
  }
}
