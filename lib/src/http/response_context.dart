library angel_framework.http.response_context;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:angel_route/angel_route.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:mime/mime.dart';
import 'server.dart' show Angel;
import 'controller.dart';
import 'request_context.dart';

final RegExp _contentType =
    new RegExp(r'([^/\n]+)\/\s*([^;\n]+)\s*(;\s*charset=([^$;\n]+))?');

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// Serializes response data into a String.
typedef String ResponseSerializer(data);

/// A convenience wrapper around an outgoing HTTP request.
class ResponseContext implements StreamSink<List<int>>, StringSink {
  final Map properties = {};
  final BytesBuilder _buffer = new _LockableBytesBuilder();
  final Map<String, String> _headers = {HttpHeaders.SERVER: 'angel'};
  final RequestContext _correspondingRequest;

  Completer _done;
  bool _isOpen = true, _isClosed = false, _useStream = false;
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

  /// Points to the [RequestContext] corresponding to this response.
  RequestContext get correspondingRequest => _correspondingRequest;

  @override
  Future get done => (_done ?? new Completer()).future;

  /// Headers that will be sent to the user.
  Map<String, String> get headers {
    /// If the response is closed, then this getter will return an immutable `Map`.
    if (_isClosed)
      return new Map<String, String>.unmodifiable(_headers);
    else
      return _headers;
  }

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
  ResponseSerializer serializer = god.serialize;

  /// This response's status code.
  int get statusCode => _statusCode;

  void set statusCode(int value) {
    if (_isClosed)
      throw _closed();
    else
      _statusCode = value ?? 200;
  }

  /// Can we still write to this response?
  bool get isOpen => _isOpen;

  /// A set of UTF-8 encoded bytes that will be written to the response.
  BytesBuilder get buffer => _buffer;

  /// The underlying [HttpResponse] under this instance.
  final HttpResponse io;

  /// Gets the Content-Type header.
  ContentType get contentType {
    if (!headers.containsKey(HttpHeaders.CONTENT_TYPE)) return null;

    var header = headers[HttpHeaders.CONTENT_TYPE];
    var match = _contentType.firstMatch(header);

    if (match == null)
      throw new Exception('Malformed Content-Type response header: "$header".');

    if (match[4]?.isNotEmpty != true)
      return new ContentType(match[1], match[2]);
    else
      return new ContentType(match[1], match[2], charset: match[4]);
  }

  /// Sets the Content-Type header.
  void set contentType(ContentType contentType) {
    headers[HttpHeaders.CONTENT_TYPE] = contentType.toString();
  }

  ResponseContext(this.io, this.app, [this._correspondingRequest]);

  /// Set this to true if you will manually close the response.
  ///
  /// If `true`, all response finalizers will be skipped.
  bool willCloseItself = false;

  StateError _closed() => new StateError('Cannot modify a closed response.');

  /// Sends a download as a response.
  Future download(File file, {String filename}) async {
    if (!_isOpen) throw _closed();

    headers["Content-Disposition"] =
        'attachment; filename="${filename ?? file.path}"';
    headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);
    headers[HttpHeaders.CONTENT_LENGTH] = file.lengthSync().toString();

    if (_useStream) {
      await file.openRead().pipe(this);
    } else {
      buffer.add(await file.readAsBytes());
      end();
    }
  }

  /// Prevents more data from being written to the response, and locks it entire from further editing.
  Future close() {
    var f = new Future.value();

    if (_useStream) {
      _useStream = false;
      _buffer?.clear();
      f = io.close();
    } else if (_buffer is _LockableBytesBuilder) {
      (_buffer as _LockableBytesBuilder)._lock();
    }

    _isOpen = _useStream = false;
    _isClosed = true;

    if (_done?.isCompleted == false) _done.complete();
    return f;
  }

  /// Prevents further request handlers from running on the response, except for response finalizers.
  ///
  /// To disable response finalizers, see [willCloseItself].
  void end() {
    _isOpen = false;
  }

  /// Serializes JSON to the response.
  void json(value) => serialize(value, contentType: ContentType.JSON);

  /// Returns a JSONP response.
  void jsonp(value, {String callbackName: "callback", contentType}) {
    if (_isClosed) throw _closed();
    write("$callbackName(${serializer(value)})");

    if (contentType != null) {
      if (contentType is ContentType)
        this.contentType = contentType;
      else
        headers[HttpHeaders.CONTENT_TYPE] = contentType.toString();
    } else
      headers[HttpHeaders.CONTENT_TYPE] = 'application/javascript';

    end();
  }

  /// Renders a view to the response stream, and closes the response.
  Future render(String view, [Map data]) async {
    if (_isClosed) throw _closed();
    write(await app.viewGenerator(view, data));
    headers[HttpHeaders.CONTENT_TYPE] = ContentType.HTML.toString();
    end();
  }

  /// Redirects to user to the given URL.
  ///
  /// [url] can be a `String`, or a `List`.
  /// If it is a `List`, a URI will be constructed
  /// based on the provided params.
  ///
  /// See [Router]#navigate for more. :)
  void redirect(url, {bool absolute: true, int code: 302}) {
    if (_isClosed) throw _closed();
    headers
      ..[HttpHeaders.CONTENT_TYPE] = ContentType.HTML.toString()
      ..[HttpHeaders.LOCATION] =
          url is String ? url : app.navigate(url, absolute: absolute);
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
    end();
  }

  /// Redirects to the given named [Route].
  void redirectTo(String name, [Map params, int code]) {
    if (_isClosed) throw _closed();
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
      redirect(matched.makeUri(params), code: code);
      return;
    }

    throw new ArgumentError.notNull('Route to redirect to ($name)');
  }

  /// Redirects to the given [Controller] action.
  void redirectToAction(String action, [Map params, int code]) {
    if (_isClosed) throw _closed();
    // UserController@show
    List<String> split = action.split("@");

    if (split.length < 2)
      throw new Exception(
          "Controller redirects must take the form of 'Controller@action'. You gave: $action");

    Controller controller =
        app.controller(split[0].replaceAll(_straySlashes, ''));

    if (controller == null)
      throw new Exception("Could not find a controller named '${split[0]}'");

    Route matched = controller.routeMappings[split[1]];

    if (matched == null)
      throw new Exception(
          "Controller '${split[0]}' does not contain any action named '${split[1]}'");

    final head =
        controller.findExpose().path.toString().replaceAll(_straySlashes, '');
    final tail = matched.makeUri(params).replaceAll(_straySlashes, '');

    redirect('$head/$tail'.replaceAll(_straySlashes, ''), code: code);
  }

  /// Copies a file's contents into the response buffer.
  Future sendFile(File file) async {
    if (_isClosed) throw _closed();

    headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);
    buffer.add(await file.readAsBytes());
    end();
  }

  /// Serializes data to the response.
  ///
  /// [contentType] can be either a [String], or a [ContentType].
  void serialize(value, {contentType}) {
    if (_isClosed) throw _closed();

    if (contentType is String)
      headers[HttpHeaders.CONTENT_TYPE] = contentType;
    else if (contentType is ContentType) this.contentType = contentType;

    var text = serializer(value);
    write(text);

    end();
  }

  /// Streams a file to this response.
  ///
  /// You can optionally transform the file stream with a [codec].
  Future streamFile(File file) {
    if (_isClosed) throw _closed();

    headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);
    return file.openRead().pipe(this);
  }

  @override
  void add(List<int> data) {
    if (_isClosed && !_useStream)
      throw _closed();
    else if (_useStream)
      io.add(data);
    else
      buffer.add(data);
  }

  /// Adds a stream directly the underlying dart:[io] response.
  ///
  /// This will also set [willCloseItself] to `true`, thus canceling out response finalizers.
  ///
  /// If this instance has access to a [correspondingRequest], then it will attempt to transform
  /// the content using at most one of the response [encoders].
  @override
  Future addStream(Stream<List<int>> stream) {
    if (_isClosed && !_useStream) throw _closed();
    bool firstStream = _useStream == false;
    willCloseItself = _useStream = _isClosed = true;

    Stream<List<int>> output = stream;

    if (firstStream) {
      // If this is the first stream added to this response,
      // then add headers, status code, etc.
      io
        ..statusCode = statusCode
        ..cookies.addAll(cookies);
      headers.forEach(io.headers.set);
    }

    if (encoders.isNotEmpty && correspondingRequest != null) {
      var allowedEncodings =
          (correspondingRequest.headers[HttpHeaders.ACCEPT_ENCODING] ?? [])
              .map((str) {
        // Ignore quality specifications in accept-encoding
        // ex. gzip;q=0.8
        if (!str.contains(';')) return str;
        return str.split(';')[0];
      });

      for (var encodingName in allowedEncodings) {
        Converter<List<int>, List<int>> encoder;
        String key = encodingName;

        if (encoders.containsKey(encodingName))
          encoder = encoders[encodingName];
        else if (encodingName == '*') {
          encoder = encoders[key = encoders.keys.first];
        }

        if (encoder != null) {
          if (firstStream) {
            io.headers.set(HttpHeaders.CONTENT_ENCODING, key);
          }

          output = encoders[key].bind(output);
          break;
        }
      }
    }

    return io.addStream(output);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    io.addError(error, stackTrace);
    if (_done?.isCompleted == false) _done.completeError(error, stackTrace);
  }

  /// Writes data to the response.
  void write(value, {Encoding encoding}) {
    encoding ??= UTF8;

    if (_isClosed && !_useStream)
      throw _closed();
    else if (_useStream) {
      if (value is List<int>)
        io.add(value);
      else
        io.add(encoding.encode(value.toString()));
    } else {
      if (value is List<int>)
        buffer.add(value);
      else
        buffer.add(encoding.encode(value.toString()));
    }
  }

  @override
  void writeCharCode(int charCode) {
    if (_isClosed && !_useStream)
      throw _closed();
    else if (_useStream)
      io.add([charCode]);
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

abstract class _LockableBytesBuilder extends BytesBuilder {
  factory _LockableBytesBuilder() => new _LockableBytesBuilderImpl();

  void _lock();
}

class _LockableBytesBuilderImpl implements _LockableBytesBuilder {
  bool _closed = false;
  Uint8List _data = new Uint8List(0);

  StateError _deny() =>
      new StateError('Cannot modified a closed response\'s buffer.');

  @override
  void _lock() {
    _closed = true;
  }

  @override
  void add(List<int> bytes) {
    if (_closed)
      throw _deny();
    else if (bytes.isNotEmpty) {
      int len = _data.length + bytes.length;
      var d = new Uint8List(len);

      for (int i = 0; i < _data.length; i++) {
        d[i] = _data[i];
      }

      for (int i = 0; i < bytes.length; i++) {
        d[i + _data.length] = bytes[i];
      }

      _data = d;
    }
  }

  @override
  void addByte(int byte) {
    if (_closed)
      throw _deny();
    else {
      int len = _data.length + 1;
      var d = new Uint8List(len);

      for (int i = 0; i < _data.length; i++) {
        d[i] = _data[i];
      }

      d[_data.length] = byte;
      _data = d;
    }
  }

  @override
  void clear() {
    if (_closed)
      throw _deny();
    else {
      for (int i = 0; i < _data.length; i++) _data[i] = 0;
    }
  }

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  int get length => _data.length;

  @override
  List<int> takeBytes() {
    if (_closed)
      return toBytes();
    else {
      var r = new Uint8List.fromList(_data);
      clear();
      return r;
    }
  }

  @override
  List<int> toBytes() {
    return _data;
  }
}
