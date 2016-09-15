library angel_framework.http.request_context;
import 'dart:async';
import 'dart:io';
import 'package:body_parser/body_parser.dart';
import '../../src/extensible.dart';
import 'angel_base.dart';
import 'route.dart';

/// A convenience wrapper around an incoming HTTP request.
class RequestContext extends Extensible {
  /// The [Angel] instance that is responding to this request.
  AngelBase app;

  /// Any cookies sent with this request.
  List<Cookie> get cookies => underlyingRequest.cookies;

  /// All HTTP headers sent with this request.
  HttpHeaders get headers => underlyingRequest.headers;

  /// The requested hostname.
  String get hostname => underlyingRequest.headers.value(HttpHeaders.HOST);

  /// The user's IP.
  String get ip => remoteAddress.address;

  /// This request's HTTP method.
  String get method => underlyingRequest.method;

  /// All post data submitted to the server.
  Map body = {};

  /// The content type of an incoming request.
  ContentType contentType;

  /// Any and all files sent to the server with this request.
  List<FileUploadInfo> files = [];

  /// The URL parameters extracted from the request URI.
  Map params = {};

  /// The requested path.
  String path;

  /// The parsed request query string.
  Map query = {};

  /// The remote address requesting this resource.
  InternetAddress remoteAddress;

  /// The route that matched this request.
  Route route;

  /// The user's HTTP session.
  HttpSession session;

  /// Is this an **XMLHttpRequest**?
  bool get xhr => underlyingRequest.headers.value("X-Requested-With")
      ?.trim()
      ?.toLowerCase() == 'xmlhttprequest';

  /// The underlying [HttpRequest] instance underneath this context.
  HttpRequest underlyingRequest;

  /// Magically transforms an [HttpRequest] into a RequestContext.
  static Future<RequestContext> from(HttpRequest request,
      Map parameters, AngelBase app, Route sourceRoute) async {
    RequestContext context = new RequestContext();

    context.app = app;
    context.contentType = request.headers.contentType;
    context.remoteAddress = request.connectionInfo.remoteAddress;
    context.params = parameters;
    context.path = request.uri.toString().replaceAll("?" + request.uri.query, "").replaceAll(new RegExp(r'\/+$'), '');
    context.route = sourceRoute;
    context.session = request.session;
    context.underlyingRequest = request;

    BodyParseResult bodyParseResult = await parseBody(request);
    context.query = bodyParseResult.query;
    context.body = bodyParseResult.body;
    context.files = bodyParseResult.files;

    return context;
  }
}