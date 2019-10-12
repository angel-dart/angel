library angel_framework.http.request_context;

import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show
        BytesBuilder,
        Cookie,
        HeaderValue,
        HttpHeaders,
        HttpSession,
        InternetAddress;

import 'package:angel_container/angel_container.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http_server/http_server.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'metadata.dart';
import 'response_context.dart';
import 'routable.dart';
import 'server.dart' show Angel;

part 'injection.dart';

/// A convenience wrapper around an incoming [RawRequest].
abstract class RequestContext<RawRequest> {
  /// Similar to [Angel.shutdownHooks], allows for logic to be executed
  /// when a [RequestContext] is done being processed.
  final List<FutureOr<void> Function()> shutdownHooks = [];

  String _acceptHeaderCache, _extensionCache;
  bool _acceptsAllCache, _hasParsedBody = false, _closed = false;
  Map<String, dynamic> _bodyFields, _queryParameters;
  List _bodyList;
  Object _bodyObject;
  List<UploadedFile> _uploadedFiles;
  MediaType _contentType;

  /// The underlying [RawRequest] provided by the driver.
  RawRequest get rawRequest;

  /// Additional params to be passed to services.
  final Map<String, dynamic> serviceParams = {};

  /// The [Angel] instance that is responding to this request.
  Angel app;

  /// Any cookies sent with this request.
  List<Cookie> get cookies;

  /// All HTTP headers sent with this request.
  HttpHeaders get headers;

  /// The requested hostname.
  String get hostname;

  /// The IoC container that can be used to provide functionality to produce
  /// objects of a given type.
  ///
  /// This is a *child* of the container found in `app`.
  Container get container;

  /// The user's IP.
  String get ip => remoteAddress.address;

  /// This request's HTTP method.
  ///
  /// This may have been processed by an override. See [originalMethod] to get the real method.
  String get method;

  /// The original HTTP verb sent to the server.
  String get originalMethod;

  /// The content type of an incoming request.
  MediaType get contentType =>
      _contentType ??= MediaType.parse(headers.contentType.toString());

  /// The URL parameters extracted from the request URI.
  Map<String, dynamic> params = <String, dynamic>{};

  /// The requested path.
  String get path;

  /// Is this an **XMLHttpRequest**?
  bool get isXhr {
    return headers.value("X-Requested-With")?.trim()?.toLowerCase() ==
        'xmlhttprequest';
  }

  /// The remote address requesting this resource.
  InternetAddress get remoteAddress;

  /// The user's HTTP session.
  HttpSession get session;

  /// The [Uri] instance representing the path this request is responding to.
  Uri get uri;

  /// The [Stream] of incoming binary data sent from the client.
  Stream<List<int>> get body;

  /// Returns `true` if [parseBody] has been called so far.
  bool get hasParsedBody => _hasParsedBody;

  /// Returns a *mutable* [Map] of the fields parsed from the request [body].
  ///
  /// Note that [parseBody] must be called first.
  Map<String, dynamic> get bodyAsMap {
    if (!hasParsedBody) {
      throw StateError('The request body has not been parsed yet.');
    } else if (_bodyFields == null) {
      throw StateError('The request body, $_bodyObject, is not a Map.');
    }

    return _bodyFields;
  }

  /// This setter allows you to explicitly set the request body **exactly once**.
  ///
  /// Use this if the format of the body is not natively parsed by Angel.
  set bodyAsMap(Map<String, dynamic> value) => bodyAsObject = value;

  /// Returns a *mutable* [List] parsed from the request [body].
  ///
  /// Note that [parseBody] must be called first.
  List get bodyAsList {
    if (!hasParsedBody) {
      throw StateError('The request body has not been parsed yet.');
    } else if (_bodyList == null) {
      throw StateError('The request body, $_bodyObject, is not a List.');
    }

    return _bodyList;
  }

  /// This setter allows you to explicitly set the request body **exactly once**.
  ///
  /// Use this if the format of the body is not natively parsed by Angel.
  set bodyAsList(List value) => bodyAsObject = value;

  /// Returns the parsed request body, whatever it may be (typically a [Map] or [List]).
  ///
  /// Note that [parseBody] must be called first.
  Object get bodyAsObject {
    if (!hasParsedBody) {
      throw StateError('The request body has not been parsed yet.');
    }

    return _bodyObject;
  }

  /// This setter allows you to explicitly set the request body **exactly once**.
  ///
  /// Use this if the format of the body is not natively parsed by Angel.
  set bodyAsObject(value) {
    if (_bodyObject != null) {
      throw StateError(
          'The request body has already been parsed/set, and cannot be overwritten.');
    } else {
      if (value is List) _bodyList = value;
      if (value is Map<String, dynamic>) _bodyFields = value;
      _bodyObject = value;
      _hasParsedBody = true;
    }
  }

  /// Returns a *mutable* map of the files parsed from the request [body].
  ///
  /// Note that [parseBody] must be called first.
  List<UploadedFile> get uploadedFiles {
    if (!hasParsedBody) {
      throw StateError('The request body has not been parsed yet.');
    }

    return _uploadedFiles;
  }

  /// Returns a *mutable* map of the fields contained in the query.
  Map<String, dynamic> get queryParameters =>
      _queryParameters ??= Map<String, dynamic>.from(uri.queryParameters);

  /// Returns the file extension of the requested path, if any.
  ///
  /// Includes the leading `.`, if there is one.
  String get extension => _extensionCache ??= p.extension(uri.path);

  /// Returns `true` if the client's `Accept` header indicates that the given [contentType] is considered a valid response.
  ///
  /// You cannot provide a `null` [contentType].
  /// If the `Accept` header's value is `*/*`, this method will always return `true`.
  /// To ignore the wildcard (`*/*`), pass [strict] as `true`.
  ///
  /// [contentType] can be either of the following:
  /// * A [ContentType], in which case the `Accept` header will be compared against its `mimeType` property.
  /// * Any other Dart value, in which case the `Accept` header will be compared against the result of a `toString()` call.
  bool accepts(contentType, {bool strict = false}) {
    var contentTypeString = contentType is MediaType
        ? contentType.mimeType
        : contentType?.toString();

    // Change to assert
    if (contentTypeString == null) {
      throw ArgumentError(
          'RequestContext.accepts expects the `contentType` parameter to NOT be null.');
    }

    _acceptHeaderCache ??= headers.value('accept');

    if (_acceptHeaderCache == null) {
      return true;
    } else if (strict != true && _acceptHeaderCache.contains('*/*')) {
      return true;
    } else {
      return _acceptHeaderCache.contains(contentTypeString);
    }
  }

  /// Returns as `true` if the client's `Accept` header indicates that it will accept any response content type.
  bool get acceptsAll => _acceptsAllCache ??= accepts('*/*');

  /// Shorthand for deserializing [bodyAsMap], using some transformer function [f].
  Future<T> deserializeBody<T>(FutureOr<T> Function(Map) f,
      {Encoding encoding = utf8}) async {
    await parseBody(encoding: encoding);
    return await f(bodyAsMap);
  }

  /// Shorthand for decoding [bodyAsMap], using some [codec].
  Future<T> decodeBody<T>(Codec<T, Map> codec, {Encoding encoding = utf8}) =>
      deserializeBody(codec.decode, encoding: encoding);

  /// Manually parses the request body, if it has not already been parsed.
  Future<void> parseBody({Encoding encoding = utf8}) async {
    if (contentType == null) {
      throw FormatException('Missing "content-type" header.');
    }

    if (!_hasParsedBody) {
      _hasParsedBody = true;

      if (contentType.type == 'application' && contentType.subtype == 'json') {
        _uploadedFiles = [];

        var parsed = _bodyObject =
            await encoding.decoder.bind(body).join().then(json.decode);

        if (parsed is Map) {
          _bodyFields = Map<String, dynamic>.from(parsed);
        } else if (parsed is List) {
          _bodyList = parsed;
        }
      } else if (contentType.type == 'application' &&
          contentType.subtype == 'x-www-form-urlencoded') {
        _uploadedFiles = [];
        var parsed = await encoding.decoder
            .bind(body)
            .join()
            .then((s) => Uri.splitQueryString(s, encoding: encoding));
        _bodyFields = Map<String, dynamic>.from(parsed);
      } else if (contentType.type == 'multipart' &&
          contentType.subtype == 'form-data' &&
          contentType.parameters.containsKey('boundary')) {
        var boundary = contentType.parameters['boundary'];
        var transformer = MimeMultipartTransformer(boundary);
        var parts = transformer.bind(body).map((part) =>
            HttpMultipartFormData.parse(part, defaultEncoding: encoding));
        _bodyFields = {};
        _uploadedFiles = [];

        await for (var part in parts) {
          if (part.isBinary) {
            _uploadedFiles.add(UploadedFile(part));
          } else if (part.isText &&
              part.contentDisposition.parameters.containsKey('name')) {
            // If there is no name, then don't parse it.
            var key = part.contentDisposition.parameters['name'];
            var value = await part.join();
            _bodyFields[key] = value;
          }
        }
      } else {
        _bodyFields = {};
        _uploadedFiles = [];
      }
    }
  }

  /// Disposes of all resources.
  @mustCallSuper
  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      _acceptsAllCache = null;
      _acceptHeaderCache = null;
      serviceParams.clear();
      params.clear();
      await Future.forEach(shutdownHooks, (hook) => hook());
    }
  }
}

/// Reads information about a binary chunk uploaded to the server.
class UploadedFile {
  /// The underlying `form-data` item.
  final HttpMultipartFormData formData;

  MediaType _contentType;

  UploadedFile(this.formData);

  /// Returns the binary stream from [formData].
  Stream<List<int>> get data => formData.cast<List<int>>();

  /// The filename associated with the data on the user's system.
  /// Returns [:null:] if not present.
  String get filename => formData.contentDisposition.parameters['filename'];

  /// The name of the field associated with this data.
  /// Returns [:null:] if not present.
  String get name => formData.contentDisposition.parameters['name'];

  /// The parsed [:Content-Type:] header of the [:HttpMultipartFormData:].
  /// Returns [:null:] if not present.
  MediaType get contentType => _contentType ??= (formData.contentType == null
      ? null
      : MediaType.parse(formData.contentType.toString()));

  /// The parsed [:Content-Transfer-Encoding:] header of the
  /// [:HttpMultipartFormData:]. This field is used to determine how to decode
  /// the data. Returns [:null:] if not present.
  HeaderValue get contentTransferEncoding => formData.contentTransferEncoding;

  /// Reads the contents of the file into a single linear buffer.
  ///
  /// Note that this leads to holding the whole file in memory, which might
  /// not be ideal for large files.w
  Future<List<int>> readAsBytes() {
    return data
        .fold<BytesBuilder>(BytesBuilder(), (bb, out) => bb..add(out))
        .then((bb) => bb.takeBytes());
  }

  /// Reads the contents of the file as [String], using the given [encoding].
  Future<String> readAsString({Encoding encoding = utf8}) {
    return encoding.decoder.bind(data).join();
  }
}
