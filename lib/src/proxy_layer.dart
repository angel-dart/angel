import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/src/base_client.dart' as http;
import 'package:http/src/request.dart' as http;
import 'package:http/src/response.dart' as http;
import 'package:http/src/streamed_response.dart' as http;

final RegExp _param = new RegExp(r':([A-Za-z0-9_]+)(\((.+)\))?');
final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

class Proxy {
  String _prefix;

  final Angel app;
  final http.BaseClient httpClient;

  /// If `true` (default), then the plug-in will ignore failures to connect to the proxy, and allow other handlers to run.
  final bool recoverFromDead;
  final bool recoverFrom404;
  final String host, mapTo, publicPath;
  final int port;
  final String protocol;
  final Duration timeout;

  Proxy(
    this.app,
    this.httpClient,
    this.host, {
    this.port,
    this.mapTo: '/',
    this.publicPath: '/',
    this.protocol: 'http',
    this.recoverFromDead: true,
    this.recoverFrom404: true,
    this.timeout,
  }) {
    _prefix = publicPath.replaceAll(_straySlashes, '');
  }

  void close() => httpClient.close();

  /// Handles an incoming HTTP request.
  Future<bool> handleRequest(RequestContext req, ResponseContext res) {
    var path = req.path.replaceAll(_straySlashes, '');

    if (_prefix?.isNotEmpty == true) {
      if (!path.startsWith(_prefix))
        return new Future<bool>.value(true);
      else {
        path = path.replaceFirst(_prefix, '').replaceAll(_straySlashes, '');
      }
    }

    return servePath(path, req, res);
  }

  /// Proxies a request to the given path on the remote server.
  Future<bool> servePath(
      String path, RequestContext req, ResponseContext res) async {
    http.StreamedResponse rs;

    final mapping = '$mapTo/$path'.replaceAll(_straySlashes, '');

    try {
      Future<http.StreamedResponse> accessRemote() async {
        var url = port == null ? host : '$host:$port';
        url = url.replaceAll(_straySlashes, '');
        url = '$url/$mapping';

        if (!url.startsWith('http')) url = 'http://$url';
        url = url.replaceAll(_straySlashes, '');

        var headers = <String, String>{
          'host': port == null ? host : '$host:$port',
          'x-forwarded-for': req.io.connectionInfo.remoteAddress.address,
          'x-forwarded-port': req.io.connectionInfo.remotePort.toString(),
          'x-forwarded-host':
              req.headers.host ?? req.headers.value('host') ?? 'none',
          'x-forwarded-proto': protocol,
        };

        req.headers.forEach((name, values) {
          headers[name] = values.join(',');
        });

        headers['cookie'] =
            req.cookies.map<String>((c) => '${c.name}=${c.value}').join('; ');

        var body;

        if (req.method != 'GET' && app.storeOriginalBuffer == true) {
          await req.parse();
          if (req.originalBuffer?.isNotEmpty == true) body = req.originalBuffer;
        }

        var rq = new http.Request(req.method, Uri.parse(url));
        rq.headers.addAll(headers);
        rq.headers['host'] = rq.url.host;

        if (body != null) rq.bodyBytes = body;

        return await httpClient.send(rq);
      }

      var future = accessRemote();
      if (timeout != null) future = future.timeout(timeout);
      rs = await future;
    } on TimeoutException catch (e, st) {
      if (recoverFromDead != false)
        return true;
      else
        throw new AngelHttpException(
          e,
          stackTrace: st,
          statusCode: 504,
          message:
              'Connection to remote host "$host" timed out after ${timeout.inMilliseconds}ms.',
        );
    } catch (e) {
      if (recoverFromDead != false)
        return true;
      else
        rethrow;
    }

    if (rs.statusCode == 404 && recoverFrom404 != false) return true;

    res
      ..statusCode = rs.statusCode
      ..headers.addAll(rs.headers);

    if (rs.contentLength == 0 && recoverFromDead != false) return true;

    var stream = rs.stream;

    if (rs.headers['content-encoding'] == 'gzip')
      stream = stream.transform(GZIP.encoder);

    await stream.pipe(res);

    return false;
  }
}
