import 'dart:async';
import 'dart:io';

import 'package:body_parser/body_parser.dart';
import 'package:http_parser/http_parser.dart';

import '../core/core.dart';

/// An implementation of [RequestContext] that wraps a [HttpRequest].
class HttpRequestContext extends RequestContext<HttpRequest> {
  MediaType _contentType;
  HttpRequest _io;
  String _override, _path;

  @override
  MediaType get contentType {
    return _contentType;
  }

  @override
  List<Cookie> get cookies {
    return rawRequest.cookies;
  }

  @override
  HttpHeaders get headers {
    return rawRequest.headers;
  }

  @override
  String get hostname {
    return rawRequest.headers.value('host');
  }

  /// The underlying [HttpRequest] instance underneath this context.
  HttpRequest get rawRequest => _io;

  @override
  String get method {
    return _override ?? originalMethod;
  }

  @override
  String get originalMethod {
    return rawRequest.method;
  }

  @override
  String get path {
    return _path;
  }

  @override
  InternetAddress get remoteAddress {
    return rawRequest.connectionInfo.remoteAddress;
  }

  @override
  HttpSession get session {
    return rawRequest.session;
  }

  @override
  Uri get uri {
    return rawRequest.uri;
  }

  @override
  bool get xhr {
    return rawRequest.headers
            .value("X-Requested-With")
            ?.trim()
            ?.toLowerCase() ==
        'xmlhttprequest';
  }

  /// Magically transforms an [HttpRequest] into a [RequestContext].
  static Future<HttpRequestContext> from(
      HttpRequest request, Angel app, String path) {
    HttpRequestContext ctx = new HttpRequestContext();

    String override = request.method;

    if (app.allowMethodOverrides == true)
      override =
          request.headers.value('x-http-method-override')?.toUpperCase() ??
              request.method;

    ctx.app = app;
    ctx._contentType = MediaType.parse(request.headers.contentType.toString());
    ctx._override = override;

    /*
    // Faster way to get path
    List<int> _path = [];

    // Go up until we reach a ?
    for (int ch in request.uri.toString().codeUnits) {
      if (ch != $question)
        _path.add(ch);
      else
        break;
    }

    // Remove trailing slashes
    int lastSlash = -1;

    for (int i = _path.length - 1; i >= 0; i--) {
      if (_path[i] == $slash)
        lastSlash = i;
      else
        break;
    }

    if (lastSlash > -1)
      ctx._path = new String.fromCharCodes(_path.take(lastSlash));
    else
      ctx._path = new String.fromCharCodes(_path);
      */

    ctx._path = path;
    ctx._io = request;

    if (app.eagerParseRequestBodies == true) {
      return ctx.parse().then((_) => ctx);
    }

    return new Future.value(ctx);
  }

  @override
  Future close() {
    _contentType = null;
    _io = null;
    _override = _path = null;
    return super.close();
  }

  @override
  Future<BodyParseResult> parseOnce() {
    return parseBodyFromStream(
        rawRequest,
        rawRequest.headers.contentType != null
            ? new MediaType.parse(rawRequest.headers.contentType.toString())
            : null,
        rawRequest.uri,
        storeOriginalBuffer: app.storeOriginalBuffer == true);
  }
}
