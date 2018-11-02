import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');
final MediaType _fallbackMediaType = MediaType('application', 'octet-stream');

class Proxy {
  String _prefix;

  final Angel app;
  final http.Client httpClient;

  /// If `true` (default), then the plug-in will ignore failures to connect to the proxy, and allow other handlers to run.
  final bool recoverFromDead;
  final bool recoverFrom404;
  final String host, mapTo, publicPath;
  final int port;
  final String protocol;

  /// If `null` then no timout is added for requests
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
    if (this.recoverFromDead == null) throw ArgumentError.notNull("recoverFromDead");
    if (this.recoverFrom404 == null) throw ArgumentError.notNull("recoverFrom404");

    _prefix = publicPath?.replaceAll(_straySlashes, '') ?? '';
  }

  void close() => httpClient.close();

  /// Handles an incoming HTTP request.
  Future<bool> handleRequest(RequestContext req, ResponseContext res) {
    var path = req.path.replaceAll(_straySlashes, '');

    if (_prefix.isNotEmpty) {
      if (!path.startsWith(_prefix)) return new Future<bool>.value(true);

      path = path.replaceFirst(_prefix, '').replaceAll(_straySlashes, '');
    }

    return servePath(path, req, res);
  }

  /// Proxies a request to the given path on the remote server.
  Future<bool> servePath(String path, RequestContext req, ResponseContext res) async {
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
          'x-forwarded-for': req.remoteAddress.address,
          'x-forwarded-port': req.uri.port.toString(),
          'x-forwarded-host': req.headers.host ?? req.headers.value('host') ?? 'none',
          'x-forwarded-proto': protocol,
        };

        req.headers.forEach((name, values) {
          headers[name] = values.join(',');
        });

        headers[HttpHeaders.cookieHeader] = req.cookies.map<String>((c) => '${c.name}=${c.value}').join('; ');

        var body;

        if (req.method != 'GET' && app.keepRawRequestBuffers == true) {
          body = (await req.parse()).originalBuffer;
        }

        var rq = new http.Request(req.method, Uri.parse(url));
        rq.headers.addAll(headers);
        rq.headers['host'] = rq.url.host;
        rq.encoding = Utf8Codec(allowMalformed: true);

        if (body != null) rq.bodyBytes = body;

        return httpClient.send(rq);
      }

      var future = accessRemote();
      if (timeout != null) future = future.timeout(timeout);
      rs = await future;
    } on TimeoutException catch (e, st) {
      if (recoverFromDead) return true;

      throw new AngelHttpException(
        e,
        stackTrace: st,
        statusCode: 504,
        message: 'Connection to remote host "$host" timed out after ${timeout.inMilliseconds}ms.',
      );
    } catch (e) {
      if (recoverFromDead) return true;
      rethrow;
    }

    if (rs.statusCode == 404 && recoverFrom404) return true;
    if (rs.contentLength == 0 && recoverFromDead) return true;

    MediaType mediaType;
    if (rs.headers.containsKey(HttpHeaders.contentTypeHeader)) {
      try {
        mediaType = MediaType.parse(rs.headers[HttpHeaders.contentTypeHeader]);
      } on FormatException catch (e, st) {
        if (recoverFromDead) return true;

        throw new AngelHttpException(
          e,
          stackTrace: st,
          statusCode: 504,
          message: 'Host "$host" returned a malformed content-type',
        );
      }
    } else {
      mediaType = _fallbackMediaType;
    }

    var proxiedHeaders = new Map<String, String>.from(rs.headers);

    res
      ..contentType = mediaType
      ..statusCode = rs.statusCode
      ..headers.addAll(proxiedHeaders);

    var stream = rs.stream;

    // [upgrading to dart2] Keeping this workaround as a reference. It's not properly typed for dart2
    //if (rs.headers[HttpHeaders.contentEncodingHeader] == 'gzip') stream = stream.transform(gzip.encoder);

    await stream.pipe(res);

    return false;
  }
}
