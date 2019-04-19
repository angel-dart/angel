library angel_framework.http.response_context;

import 'dart:async';
import 'dart:convert';
import 'dart:convert' as c show json;
import 'dart:io' show BytesBuilder, Cookie;

import 'package:angel_route/angel_route.dart';
import 'package:file/file.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'controller.dart';
import 'request_context.dart';
import 'server.dart' show Angel;

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// A convenience wrapper around an outgoing HTTP request.
abstract class ResponseContext<RawResponse>
    implements StreamSink<List<int>>, StringSink {
  final Map properties = {};
  final CaseInsensitiveMap<String> _headers =
      new CaseInsensitiveMap<String>.from({
    'content-type': 'text/plain',
    'server': 'angel',
  });

  Completer _done;
  int _statusCode = 200;

  /// The [Angel] instance that is sending a response.
  Angel app;

  /// Is `Transfer-Encoding` chunked?
  bool chunked;

  /// Any and all cookies to be sent to the user.
  final List<Cookie> cookies = [];

  /// A set of [Converter] objects that can be used to encode response data.
  ///
  /// At most one encoder will ever be used to convert data.
  final Map<String, Converter<List<int>, List<int>>> encoders = {};

  /// A [Map] of data to inject when `res.render` is called.
  ///
  /// This can be used to reduce boilerplate when using templating engines.
  final Map<String, dynamic> renderParams = {};

  /// Points to the [RequestContext] corresponding to this response.
  RequestContext get correspondingRequest;

  @override
  Future get done => (_done ?? new Completer()).future;

  /// Headers that will be sent to the user.
  ///
  /// Note that if you have already started writing to the underlying stream, headers will not persist.
  CaseInsensitiveMap<String> get headers => _headers;

  /// Serializes response data into a String.
  ///
  /// The default is conversion into JSON via `package:json_god`.
  ///
  /// If you are 100% sure that your response handlers will only
  /// be JSON-encodable objects (i.e. primitives, `List`s and `Map`s),
  /// then consider setting [serializer] to `JSON.encode`.
  ///
  /// To set it globally for the whole [app], use the following helper:
  /// ```dart
  /// app.injectSerializer(JSON.encode);
  /// ```
  FutureOr<String> Function(dynamic) serializer = c.json.encode;

  /// This response's status code.
  int get statusCode => _statusCode;

  set statusCode(int value) {
    if (!isOpen)
      throw closed();
    else
      _statusCode = value ?? 200;
  }

  /// Returns `true` if the response is still available for processing by Angel.
  ///
  /// If it is `false`, then Angel will stop executing handlers, and will only run
  /// response finalizers if the response [isBuffered].
  bool get isOpen;

  /// Returns `true` if response data is being written to a buffer, rather than to the underlying stream.
  bool get isBuffered;

  /// A set of UTF-8 encoded bytes that will be written to the response.
  BytesBuilder get buffer;

  /// The underlying [RawResponse] under this instance.
  RawResponse get rawResponse;

  /// Signals Angel that the response is being held alive deliberately, and that the framework should not automatically close it.
  ///
  /// This is mostly used in situations like WebSocket handlers, where the connection should remain
  /// open indefinitely.
  FutureOr<RawResponse> detach();

  /// Gets or sets the content length to send back to a client.
  ///
  /// Returns `null` if the header is invalidly formatted.
  int get contentLength {
    return int.tryParse(headers['content-length']);
  }

  /// Gets or sets the content length to send back to a client.
  ///
  /// If [value] is `null`, then the header will be removed.
  set contentLength(int value) {
    if (value == null)
      headers.remove('content-length');
    else
      headers['content-length'] = value.toString();
  }

  /// Gets or sets the content type to send back to a client.
  MediaType get contentType {
    try {
      return new MediaType.parse(headers['content-type']);
    } catch (_) {
      return new MediaType('text', 'plain');
    }
  }

  /// Gets or sets the content type to send back to a client.
  set contentType(MediaType value) {
    headers['content-type'] = value.toString();
  }

  static StateError closed() =>
      new StateError('Cannot modify a closed response.');

  /// Sends a download as a response.
  Future<void> download(File file, {String filename}) async {
    if (!isOpen) throw closed();

    headers["Content-Disposition"] =
        'attachment; filename="${filename ?? file.path}"';
    contentType = MediaType.parse(lookupMimeType(file.path));
    headers['content-length'] = file.lengthSync().toString();

    if (!isBuffered) {
      await file.openRead().pipe(this);
    } else {
      buffer.add(file.readAsBytesSync());
      await close();
    }
  }

  /// Prevents more data from being written to the response, and locks it entire from further editing.
  Future<void> close() {
    if (buffer is LockableBytesBuilder) {
      (buffer as LockableBytesBuilder).lock();
    }

    if (_done?.isCompleted == false) _done.complete();
    return new Future.value();
  }

  /// Serializes JSON to the response.
  void json(value) => this
    ..contentType = MediaType('application', 'json')
    ..serialize(value);

  /// Returns a JSONP response.
  ///
  /// You can override the [contentType] sent; by default it is `application/javascript`.
  Future<void> jsonp(value,
      {String callbackName = "callback", MediaType contentType}) {
    if (!isOpen) throw closed();
    this.contentType =
        contentType ?? new MediaType('application', 'javascript');
    write("$callbackName(${serializer(value)})");
    return close();
  }

  /// Renders a view to the response stream, and closes the response.
  Future<void> render(String view, [Map<String, dynamic> data]) {
    if (!isOpen) throw closed();
    contentType = new MediaType('text', 'html', {'charset': 'utf-8'});
    return Future<String>.sync(() => app.viewGenerator(
        view,
        new Map<String, dynamic>.from(renderParams)
          ..addAll(data ?? <String, dynamic>{}))).then((content) {
      write(content);
      return close();
    });
  }

  /// Redirects to user to the given URL.
  ///
  /// [url] can be a `String`, or a `List`.
  /// If it is a `List`, a URI will be constructed
  /// based on the provided params.
  ///
  /// See [Router]#navigate for more. :)
  Future<void> redirect(url, {bool absolute = true, int code = 302}) {
    if (!isOpen) throw closed();
    headers
      ..['content-type'] = 'text/html'
      ..['location'] = (url is String || url is Uri)
          ? url.toString()
          : app.navigate(url as Iterable, absolute: absolute);
    statusCode = code ?? 302;
    write('''
    <!DOCTYPE html>
    <html>
      <head>
        <title>Redirecting...</title>
        <meta http-equiv="refresh" content="0; url=$url">
      </head>
      <body>
        <h1>Currently redirecting you...</h1>
        <br />
        Click <a href="$url">here</a> if you are not automatically redirected...
        <script>
          window.location = "$url";
        </script>
      </body>
    </html>
    ''');
    return close();
  }

  /// Redirects to the given named [Route].
  Future<void> redirectTo(String name, [Map params, int code]) async {
    if (!isOpen) throw closed();
    Route _findRoute(Router r) {
      for (Route route in r.routes) {
        if (route is SymlinkRoute) {
          final m = _findRoute(route.router);

          if (m != null) return m;
        } else if (route.name == name) return route;
      }

      return null;
    }

    Route matched = _findRoute(app);

    if (matched != null) {
      await redirect(
          matched.makeUri(params.keys.fold<Map<String, dynamic>>({}, (out, k) {
            return out..[k.toString()] = params[k];
          })),
          code: code);
      return;
    }

    throw new ArgumentError.notNull('Route to redirect to ($name)');
  }

  /// Redirects to the given [Controller] action.
  Future<void> redirectToAction(String action, [Map params, int code]) {
    if (!isOpen) throw closed();
    // UserController@show
    List<String> split = action.split("@");

    if (split.length < 2)
      throw new Exception(
          "Controller redirects must take the form of 'Controller@action'. You gave: $action");

    Controller controller =
        app.controllers[split[0].replaceAll(_straySlashes, '')];

    if (controller == null)
      throw new Exception("Could not find a controller named '${split[0]}'");

    Route matched = controller.routeMappings[split[1]];

    if (matched == null)
      throw new Exception(
          "Controller '${split[0]}' does not contain any action named '${split[1]}'");

    final head = controller
        .findExpose(app.container.reflector)
        .path
        .toString()
        .replaceAll(_straySlashes, '');
    final tail = matched
        .makeUri(params.keys.fold<Map<String, dynamic>>({}, (out, k) {
          return out..[k.toString()] = params[k];
        }))
        .replaceAll(_straySlashes, '');

    return redirect('$head/$tail'.replaceAll(_straySlashes, ''), code: code);
  }

  /// Serializes data to the response.
  Future<bool> serialize(value, {MediaType contentType}) async {
    if (!isOpen) throw closed();
    this.contentType = contentType ?? new MediaType('application', 'json');
    var text = await serializer(value);
    if (text.isEmpty) return true;
    write(text);
    await close();
    return false;
  }

  /// Streams a file to this response.
  ///
  /// `HEAD` responses will not actually write data.
  Future streamFile(File file) async {
    if (!isOpen) throw closed();
    var mimeType = app.mimeTypeResolver.lookup(file.path);
    contentLength = await file.length();
    contentType = mimeType == null
        ? new MediaType('application', 'octet-stream')
        : MediaType.parse(mimeType);

    if (correspondingRequest.method != 'HEAD')
      return file.openRead().pipe(this);
  }

  /// Configure the response to write to an intermediate response buffer, rather than to the stream directly.
  void useBuffer();

  /// Adds a stream directly the underlying response.
  ///
  /// If this instance has access to a [correspondingRequest], then it will attempt to transform
  /// the content using at most one of the response [encoders].
  @override
  Future addStream(Stream<List<int>> stream);

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    if (_done?.isCompleted == false)
      _done.completeError(error, stackTrace);
    else if (_done == null) Zone.current.handleUncaughtError(error, stackTrace);
  }

  /// Writes data to the response.
  void write(value, {Encoding encoding}) {
    encoding ??= utf8;

    if (!isOpen && isBuffered)
      throw closed();
    else if (!isBuffered) {
      add(encoding.encode(value.toString()));
    } else {
      buffer.add(encoding.encode(value.toString()));
    }
  }

  @override
  void writeCharCode(int charCode) {
    if (!isOpen && isBuffered)
      throw closed();
    else if (!isBuffered)
      add([charCode]);
    else
      buffer.addByte(charCode);
  }

  @override
  void writeln([Object obj = ""]) {
    write(obj.toString());
    write('\r\n');
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    write(objects.join(separator));
  }
}

abstract class LockableBytesBuilder extends BytesBuilder {
  factory LockableBytesBuilder() {
    return new _LockableBytesBuilderImpl();
  }

  void lock();
}

class _LockableBytesBuilderImpl implements LockableBytesBuilder {
  final BytesBuilder _buf = new BytesBuilder(copy: false);
  bool _closed = false;

  StateError _deny() =>
      new StateError('Cannot modified a closed response\'s buffer.');

  @override
  void lock() {
    _closed = true;
  }

  @override
  void add(List<int> bytes) {
    if (_closed)
      throw _deny();
    else
      _buf.add(bytes);
  }

  @override
  void addByte(int byte) {
    if (_closed)
      throw _deny();
    else
      _buf.addByte(byte);
  }

  @override
  void clear() {
    _buf.clear();
  }

  @override
  bool get isEmpty => _buf.isEmpty;

  @override
  bool get isNotEmpty => _buf.isNotEmpty;

  @override
  int get length => _buf.length;

  @override
  List<int> takeBytes() {
    return _buf.takeBytes();
  }

  @override
  List<int> toBytes() {
    return _buf.toBytes();
  }
}
