import 'dart:async';
import 'dart:io';
import 'package:body_parser/body_parser.dart';
import '../core/core.dart';

/// An implementation of [RequestContext] that wraps a [HttpRequest].
class HttpRequestContextImpl extends RequestContext {
  ContentType _contentType;
  HttpRequest _io;
  String _override, _path;

  @override
  ContentType get contentType {
    return _contentType;
  }

  @override
  List<Cookie> get cookies {
    return io.cookies;
  }

  @override
  HttpHeaders get headers {
    return io.headers;
  }

  @override
  String get hostname {
    return io.headers.value(HttpHeaders.HOST);
  }

  /// The underlying [HttpRequest] instance underneath this context.
  HttpRequest get io => _io;

  @override
  String get method {
    return  _override ?? originalMethod;
  }

  @override
  String get originalMethod {
    return io.method;
  }

  @override
  String get path {
    return _path;
  }

  @override
  InternetAddress get remoteAddress {
    return io.connectionInfo.remoteAddress;
  }

  @override
  HttpSession get session {
    return io.session;
  }

  @override
  Uri get uri {
    return io.uri;
  }

  @override
  bool get xhr {
    return io.headers.value("X-Requested-With")?.trim()?.toLowerCase() ==
        'xmlhttprequest';
  }

  /// Magically transforms an [HttpRequest] into a [RequestContext].
  static Future<HttpRequestContextImpl> from(
      HttpRequest request, Angel app, String path) async {
    HttpRequestContextImpl ctx = new HttpRequestContextImpl();

    String override = request.method;

    if (app.allowMethodOverrides == true)
      override =
          request.headers.value('x-http-method-override')?.toUpperCase() ??
              request.method;

    ctx.app = app;
    ctx._contentType = request.headers.contentType;
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

    if (app.lazyParseBodies != true) {
      await ctx.parse();
    }

    return ctx;
  }

  @override
  Future close() {
    _contentType = null;
    _io = null;
    _override = _path = null;
    return super.close();
  }

  @override
  Future<BodyParseResult> parseOnce() async {
    return await parseBody(io,
        storeOriginalBuffer: app.storeOriginalBuffer == true);
  }
}
