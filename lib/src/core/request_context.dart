library angel_framework.http.request_context;

import 'dart:async';
import 'dart:io' show Cookie, HttpHeaders, HttpSession, InternetAddress;
import 'dart:mirrors';

import 'package:body_parser/body_parser.dart';
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'metadata.dart';
import 'response_context.dart';
import 'routable.dart';
import 'server.dart' show Angel;

part 'injection.dart';

/// A convenience wrapper around an incoming [RawRequest].
abstract class RequestContext<RawRequest> {
  String _acceptHeaderCache, _extensionCache;
  bool _acceptsAllCache;
  BodyParseResult _body;
  Map _provisionalQuery;

  final Map properties = {};

  /// The underlying [RawRequest] provided by the driver.
  RawRequest get rawRequest;

  /// Additional params to be passed to services.
  final Map serviceParams = {};

  /// The [Angel] instance that is responding to this request.
  Angel app;

  /// Any cookies sent with this request.
  List<Cookie> get cookies;

  /// All HTTP headers sent with this request.
  HttpHeaders get headers;

  /// The requested hostname.
  String get hostname;

  final Map _injections = {};

  /// A [Map] of singletons injected via [inject].
  Map get injections => _injections;

  /// The user's IP.
  String get ip => remoteAddress.address;

  /// This request's HTTP method.
  ///
  /// This may have been processed by an override. See [originalMethod] to get the real method.
  String get method;

  /// The original HTTP verb sent to the server.
  String get originalMethod;

  /// The content type of an incoming request.
  MediaType get contentType;

  /// The URL parameters extracted from the request URI.
  Map params = {};

  /// The requested path.
  String get path;

  /// The remote address requesting this resource.
  InternetAddress get remoteAddress;

  /// The user's HTTP session.
  HttpSession get session;

  /// The [Uri] instance representing the path this request is responding to.
  Uri get uri;

  /// Is this an **XMLHttpRequest**?
  bool get xhr;

  /// Returns the file extension of the requested path, if any.
  ///
  /// Includes the leading `.`, if there is one.
  String get extension => _extensionCache ??= p.extension(uri.path);

  /// Grabs an object by key or type from [params], [_injections], or
  /// [app].container. Use this to perform dependency injection
  /// within a service hook.
  T grab<T>(key) {
    if (params.containsKey(key))
      return params[key] as T;
    else if (_injections.containsKey(key))
      return _injections[key] as T;
    else if (properties.containsKey(key))
      return properties[key] as T;
    else {
      var prop = app?.findProperty(key);
      if (prop != null)
        return prop as T;
      else if (key is Type) {
        try {
          return app.container.make(key) as T;
        } catch (e) {
          return null;
        }
      } else
        return null;
    }
  }

  /// Shorthand to add to [_injections].
  void inject(type, value) {
    if (!app.isProduction && type is Type) {
      if (!reflect(value).type.isAssignableTo(reflectType(type)))
        throw new ArgumentError(
            'Cannot inject $value (${value.runtimeType}) as an instance of $type.');
    }

    _injections[type] = value;
  }

  /// Returns `true` if the client's `Accept` header indicates that the given [contentType] is considered a valid response.
  ///
  /// You cannot provide a `null` [contentType].
  /// If the `Accept` header's value is `*/*`, this method will always return `true`.
  /// To ignore the wildcard (`*/*`), pass [strict] as `true`.
  ///
  /// [contentType] can be either of the following:
  /// * A [ContentType], in which case the `Accept` header will be compared against its `mimeType` property.
  /// * Any other Dart value, in which case the `Accept` header will be compared against the result of a `toString()` call.
  bool accepts(contentType, {bool strict: false}) {
    var contentTypeString = contentType is MediaType
        ? contentType.mimeType
        : contentType?.toString();

    // Change to assert
    if (contentTypeString == null)
      throw new ArgumentError(
          'RequestContext.accepts expects the `contentType` parameter to NOT be null.');

    _acceptHeaderCache ??= headers.value('accept');

    if (_acceptHeaderCache == null)
      return false;
    else if (strict != true && _acceptHeaderCache.contains('*/*'))
      return true;
    else
      return _acceptHeaderCache.contains(contentTypeString);
  }

  /// Returns as `true` if the client's `Accept` header indicates that it will accept any response content type.
  bool get acceptsAll => _acceptsAllCache ??= accepts('*/*');

  /// Retrieves the request body if it has already been parsed, or lazy-parses it before returning the body.
  Future<Map> parseBody() => parse().then((b) => b.body);

  /// Retrieves a list of all uploaded files if it has already been parsed, or lazy-parses it before returning the files.
  Future<List<FileUploadInfo>> parseUploadedFiles() => parse().then((b) => b.files);

  /// Retrieves the original request buffer if it has already been parsed, or lazy-parses it before returning the buffer..
  ///
  /// This will return an empty `List` if you have not enabled `keepRawRequestBuffers` on your [Angel] instance.
  Future<List<int>> parseRawRequestBuffer() =>
      parse().then((b) => b.originalBuffer);

  /// Retrieves the request body if it has already been parsed, or lazy-parses it before returning the query.
  ///
  /// If [forceParse] is not `true`, then [uri].query will be returned, and no parsing will be performed.
  Future<Map<String, dynamic>> parseQuery({bool forceParse: false}) {
    if (_body == null && forceParse != true)
      return new Future.value(uri.queryParameters);
    else
      return parse().then((b) => b.query);
  }

  /// Manually parses the request body, if it has not already been parsed.
  Future<BodyParseResult> parse() {
    if (_body != null)
      return new Future.value(_body);
    else
      _provisionalQuery = null;
    return parseOnce().then((body) => _body = body);
  }

  /// Override this method to one-time parse an incoming request.
  @virtual
  Future<BodyParseResult> parseOnce();

  /// Disposes of all resources.
  Future close() {
    _body = null;
    _acceptsAllCache = null;
    _acceptHeaderCache = null;
    _provisionalQuery?.clear();
    properties.clear();
    _injections.clear();
    serviceParams.clear();
    params.clear();
    return new Future.value();
  }
}
