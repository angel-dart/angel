library angel_framework.http.request_context;

import 'dart:async';
import 'dart:io';
import 'package:angel_route/src/extensible.dart';
import 'package:body_parser/body_parser.dart';
import 'angel_base.dart';

/// A convenience wrapper around an incoming HTTP request.
class RequestContext extends Extensible {
  BodyParseResult _body;
  ContentType _contentType;
  HttpRequest _io;
  String _path;

  /// The [Angel] instance that is responding to this request.
  AngelBase app;

  /// Any cookies sent with this request.
  List<Cookie> get cookies => io.cookies;

  /// All HTTP headers sent with this request.
  HttpHeaders get headers => io.headers;

  /// The requested hostname.
  String get hostname => io.headers.value(HttpHeaders.HOST);

  /// A [Map] of values that should be DI'd.
  final Map injections = {};

  /// The underlying [HttpRequest] instance underneath this context.
  HttpRequest get io => _io;

  /// The user's IP.
  String get ip => remoteAddress.address;

  /// This request's HTTP method.
  String get method => io.method;

  /// All post data submitted to the server.
  Map get body => _body.body;

  /// The content type of an incoming request.
  ContentType get contentType => _contentType;

  /// Any and all files sent to the server with this request.
  List<FileUploadInfo> get files => _body.files;

  /// The URL parameters extracted from the request URI.
  Map params = {};

  /// The requested path.
  String get path => _path;

  /// The parsed request query string.
  Map get query => _body.query;

  /// The remote address requesting this resource.
  InternetAddress get remoteAddress => io.connectionInfo.remoteAddress;

  /// The user's HTTP session.
  HttpSession get session => io.session;

  /// The [Uri] instance representing the path this request is responding to.
  Uri get uri => io.uri;

  /// Is this an **XMLHttpRequest**?
  bool get xhr =>
      io.headers.value("X-Requested-With")?.trim()?.toLowerCase() ==
      'xmlhttprequest';

  @deprecated
  HttpRequest get underlyingRequest {
    throw new Exception(
        '`RequestContext#underlyingRequest` is deprecated. Please update your application to use the newer `RequestContext#io`.');
  }

  /// Magically transforms an [HttpRequest] into a [RequestContext].
  static Future<RequestContext> from(HttpRequest request, AngelBase app) async {
    RequestContext ctx = new RequestContext();

    ctx.app = app;
    ctx._contentType = request.headers.contentType;
    ctx._path = request.uri
        .toString()
        .replaceAll("?" + request.uri.query, "")
        .replaceAll(new RegExp(r'/+$'), '');
    ctx._io = request;

    ctx._body = (await parseBody(request,
            storeOriginalBuffer: app.storeOriginalBuffer == true)) ??
        {};

    return ctx;
  }

  void inject(type, value) {
    injections[type] = value;
  }
}
