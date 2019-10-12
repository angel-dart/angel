import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

final RegExp _straySlashes = RegExp(r'(^/+)|(/+$)');
final MediaType _fallbackMediaType = MediaType('application', 'octet-stream');

/// A middleware class that forwards requests (reverse proxies) to an upstream server.
///
/// Supports WebSockets, in addition to regular HTTP requests.
class Proxy {
  String _prefix;

  /// The underlying [Client] to use.
  final http.Client httpClient;

  /// If `true` (default), then the plug-in will ignore failures to connect to the proxy, and allow other handlers to run.
  final bool recoverFromDead;
  final bool recoverFrom404;
  final Uri baseUrl;
  final String publicPath;

  /// If `null` then no timout is added for requests
  final Duration timeout;

  Proxy(
    baseUrl, {
    http.Client httpClient,
    this.publicPath = '/',
    this.recoverFromDead = true,
    this.recoverFrom404 = true,
    this.timeout,
  })  : this.baseUrl = baseUrl is Uri ? baseUrl : Uri.parse(baseUrl.toString()),
        this.httpClient = httpClient ?? http.Client() {
    if (!this.baseUrl.hasScheme || !this.baseUrl.hasAuthority) {
      throw ArgumentError(
          'Invalid `baseUrl`. URI must have both a scheme and authority.');
    }
    if (this.recoverFromDead == null) {
      throw ArgumentError.notNull("recoverFromDead");
    }
    if (this.recoverFrom404 == null) {
      throw ArgumentError.notNull("recoverFrom404");
    }

    _prefix = publicPath?.replaceAll(_straySlashes, '') ?? '';
  }

  void close() => httpClient.close();

  /// A handler that serves the file at the given path, unless the user has requested that path.
  ///
  /// You can also limit this functionality to specific values of the `Accept` header, ex. `text/html`.
  /// If [accepts] is `null`, OR at least one of the content types in [accepts] is present,
  /// the view will be served.
  RequestHandler pushState(String path, {Iterable accepts}) {
    var vPath = path.replaceAll(_straySlashes, '');
    if (_prefix?.isNotEmpty == true) vPath = '$_prefix/$vPath';

    return (RequestContext req, ResponseContext res) {
      var path = req.path.replaceAll(_straySlashes, '');
      if (path == vPath) return Future<bool>.value(true);

      if (accepts?.isNotEmpty == true) {
        if (!accepts.any((x) => req.accepts(x, strict: true))) {
          return Future<bool>.value(true);
        }
      }

      return servePath(vPath, req, res);
    };
  }

  /// Handles an incoming HTTP request.
  Future<bool> handleRequest(RequestContext req, ResponseContext res) {
    var path = req.path.replaceAll(_straySlashes, '');

    if (_prefix.isNotEmpty) {
      if (!p.isWithin(_prefix, path) && !p.equals(_prefix, path)) {
        return Future<bool>.value(true);
      }

      path = p.relative(path, from: _prefix);
    }

    return servePath(path, req, res);
  }

  /// Proxies a request to the given path on the remote server.
  Future<bool> servePath(
      String path, RequestContext req, ResponseContext res) async {
    http.StreamedResponse rs;

    var uri = baseUrl.replace(path: p.join(baseUrl.path, path));

    try {
      if (req is HttpRequestContext &&
          WebSocketTransformer.isUpgradeRequest(req.rawRequest)) {
        res.detach();
        uri = uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');

        try {
          var local = await WebSocketTransformer.upgrade(req.rawRequest);
          var remote = await WebSocket.connect(uri.toString());

          scheduleMicrotask(() => local.pipe(remote));
          scheduleMicrotask(() => remote.pipe(local));
          return false;
        } catch (e, st) {
          throw AngelHttpException(e,
              message: 'Could not connect WebSocket', stackTrace: st);
        }
      }

      Future<http.StreamedResponse> accessRemote() async {
        var headers = <String, String>{
          'host': uri.authority,
          'x-forwarded-for': req.remoteAddress.address,
          'x-forwarded-port': req.uri.port.toString(),
          'x-forwarded-host':
              req.headers.host ?? req.headers.value('host') ?? 'none',
          'x-forwarded-proto': uri.scheme,
        };

        req.headers.forEach((name, values) {
          headers[name] = values.join(',');
        });

        headers[HttpHeaders.cookieHeader] =
            req.cookies.map<String>((c) => '${c.name}=${c.value}').join('; ');

        List<int> body;

        if (!req.hasParsedBody) {
          body = await req.body
              .fold<BytesBuilder>(BytesBuilder(), (bb, buf) => bb..add(buf))
              .then((bb) => bb.takeBytes());
        }

        var rq = http.Request(req.method, uri);
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

      throw AngelHttpException(
        e,
        stackTrace: st,
        statusCode: 504,
        message:
            'Connection to remote host "$uri" timed out after ${timeout.inMilliseconds}ms.',
      );
    } catch (e) {
      if (recoverFromDead && e is! AngelHttpException) return true;
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

        throw AngelHttpException(
          e,
          stackTrace: st,
          statusCode: 504,
          message: 'Host "$uri" returned a malformed content-type',
        );
      }
    } else {
      mediaType = _fallbackMediaType;
    }

    /// if [http.Client] does not provide us with a content length
    /// OR [http.Client] is about to decode the response (bytecount returned by [http.Response].stream != known length)
    /// then we can not provide a value downstream => set to '-1' for 'unspecified length'
    var isContentLengthUnknown = rs.contentLength == null ||
        rs.headers[HttpHeaders.contentEncodingHeader]?.isNotEmpty == true ||
        rs.headers[HttpHeaders.transferEncodingHeader]?.isNotEmpty == true;

    var proxiedHeaders = Map<String, String>.from(rs.headers)
      ..remove(
          HttpHeaders.contentEncodingHeader) // drop, http.Client has decoded
      ..remove(
          HttpHeaders.transferEncodingHeader) // drop, http.Client has decoded
      ..[HttpHeaders.contentLengthHeader] =
          "${isContentLengthUnknown ? '-1' : rs.contentLength}";

    res
      ..contentType = mediaType
      ..statusCode = rs.statusCode
      ..headers.addAll(proxiedHeaders);

    await rs.stream.pipe(res);

    return false;
  }
}
