library angel_framework.http.request_context;

import 'dart:async';
import 'dart:io';
import 'package:angel_route/src/extensible.dart';
import 'package:body_parser/body_parser.dart';
import 'server.dart' show Angel;

/// A convenience wrapper around an incoming HTTP request.
class RequestContext extends Extensible {
  String _acceptHeaderCache;
  bool _acceptsAllCache;
  BodyParseResult _body;
  ContentType _contentType;
  HttpRequest _io;
  String _override, _path;

  /// Additional params to be passed to services.
  final Map serviceParams = {};

  /// The [Angel] instance that is responding to this request.
  Angel app;

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
  ///
  /// This may have been processed by an override. See [originalMethod] to get the real method.
  String get method => _override ?? originalMethod;

  /// The original HTTP verb sent to the server.
  String get originalMethod => io.method;

  StateError _unparsed(String type, String caps) => new StateError(
      'Cannot get the $type of an unparsed request. Use lazy${caps}() instead.');

  /// All post data submitted to the server.
  ///
  /// If you are lazy-parsing request bodies, but have not manually [parse]d this one,
  /// then an error will be thrown.
  ///
  /// **If you are writing a plug-in, use [lazyBody] instead.**
  Map get body {
    if (_body == null)
      throw _unparsed('body', 'Body');
    else
      return _body.body;
  }

  /// The content type of an incoming request.
  ContentType get contentType => _contentType;

  /// Any and all files sent to the server with this request.
  ///
  /// If you are lazy-parsing request bodies, but have not manually [parse]d this one,
  /// then an error will be thrown.
  ///
  /// **If you are writing a plug-in, use [lazyFiles] instead.**
  List<FileUploadInfo> get files {
    if (_body == null)
      throw _unparsed('query', 'Files');
    else
      return _body.files;
  }

  /// The original body bytes sent with this request. May be empty.
  ///
  /// If you are lazy-parsing request bodies, but have not manually [parse]d this one,
  /// then an error will be thrown.
  ///
  /// **If you are writing a plug-in, use [lazyOriginalBuffer] instead.**
  List<int> get originalBuffer {
    if (_body == null)
      throw _unparsed('original buffer', 'OriginalBuffer');
    else
      return _body.originalBuffer ?? [];
  }

  /// The URL parameters extracted from the request URI.
  Map params = {};

  /// The requested path.
  String get path => _path;

  /// The parsed request query string.
  ///
  /// If you are lazy-parsing request bodies, but have not manually [parse]d this one,
  /// then [uri].query will be returned.
  ///
  /// **If you are writing a plug-in, consider using [lazyQuery] instead.**
  Map get query {
    if (_body == null)
      return uri.queryParameters;
    else
      return _body.query;
  }

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
  static Future<RequestContext> from(HttpRequest request, Angel app) async {
    RequestContext ctx = new RequestContext();

    String override = request.method;

    if (app.allowMethodOverrides == true)
      override =
          request.headers.value('x-http-method-override')?.toUpperCase() ??
              request.method;

    ctx.app = app;
    ctx._contentType = request.headers.contentType;
    ctx._override = override;
    ctx._path = request.uri
        .toString()
        .replaceAll("?" + request.uri.query, "")
        .replaceAll(new RegExp(r'/+$'), '');
    ctx._io = request;

    if (app.lazyParseBodies != true)
      ctx._body = (await parseBody(request,
              storeOriginalBuffer: app.storeOriginalBuffer == true)) ??
          {};

    return ctx;
  }

  /// Grabs an object by key or type from [params], [injections], or
  /// [app].container. Use this to perform dependency injection
  /// within a service hook.
  T grab<T>(key) {
    if (params.containsKey(key))
      return params[key];
    else if (injections.containsKey(key))
      return injections[key];
    else if (properties.containsKey(key))
      return properties[key];
    else {
      var prop = app?.findProperty(key);
      if (prop != null)
        return prop;
      else if (key is Type) {
        try {
          return app.container.make(key);
        } catch (e) {
          return null;
        }
      } else
        return null;
    }
  }

  /// Shorthand to add to [injections].
  void inject(type, value) {
    injections[type] = value;
  }

  /// Returns `true` if the client's `Accept` header indicates that the given [contentType] is considered a valid response.
  ///
  /// You cannot provide a `null` [contentType].
  /// If the `Accept` header's value is `*/*`, this method will always return `true`.
  ///
  /// [contentType] can be either of the following:
  /// * A [ContentType], in which case the `Accept` header will be compared against its `mimeType` property.
  /// * Any other Dart value, in which case the `Accept` header will be compared against the result of a `toString()` call.
  bool accepts(contentType) {
    var contentTypeString = contentType is ContentType
        ? contentType.mimeType
        : contentType?.toString();

    if (contentTypeString == null)
      throw new ArgumentError(
          'RequestContext.accepts expects the `contentType` parameter to NOT be null.');

    _acceptHeaderCache ??= headers.value(HttpHeaders.ACCEPT);

    if (_acceptHeaderCache == null)
      return false;
    else if (_acceptHeaderCache.contains('*/*'))
      return true;
    else
      return _acceptHeaderCache.contains(contentTypeString);
  }

  /// Returns as `true` if the client's `Accept` header indicates that it will accept any response content type.
  bool get acceptsAll => _acceptsAllCache ??= accepts('*/*');

  /// Retrieves the request body if it has already been parsed, or lazy-parses it before returning the body.
  Future<Map> lazyBody() => parse().then((b) => b.body);

  /// Retrieves the request files if it has already been parsed, or lazy-parses it before returning the files.
  Future<List<FileUploadInfo>> lazyFiles() => parse().then((b) => b.files);

  /// Retrieves the original request buffer if it has already been parsed, or lazy-parses it before returning the files.
  ///
  /// This will return an empty `List` if you have not enabled `storeOriginalBuffer` on your [app] instance.
  Future<List<int>> lazyOriginalBuffer() =>
      parse().then((b) => b.originalBuffer);

  /// Retrieves the request body if it has already been parsed, or lazy-parses it before returning the query.
  ///
  /// If [forceParse] is not `true`, then [uri].query will be returned, and no parsing will be performed.
  Future<Map<String, dynamic>> lazyQuery({bool forceParse: false}) {
    if (_body == null && forceParse != true)
      return new Future.value(uri.queryParameters);
    else
      return parse().then((b) => b.query);
  }

  /// Manually parses the request body, if it has not already been parsed.
  Future<BodyParseResult> parse() async {
    if (_body != null)
      return _body;
    else
      return _body = await parseBody(io,
          storeOriginalBuffer: app.storeOriginalBuffer == true);
  }
}
