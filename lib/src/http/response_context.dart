library angel_framework.http.response_context;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_route/angel_route.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:mime/mime.dart';
import '../extensible.dart';
import 'server.dart' show Angel;
import 'controller.dart';

final RegExp _contentType =
    new RegExp(r'([^/\n]+)\/\s*([^;\n]+)\s*(;\s*charset=([^$;\n]+))?');

final RegExp _straySlashes = new RegExp(r'(^/+)|(/+$)');

/// Serializes response data into a String.
typedef String ResponseSerializer(data);

/// A convenience wrapper around an outgoing HTTP request.
class ResponseContext extends Extensible {
  bool _isOpen = true;

  /// The [Angel] instance that is sending a response.
  Angel app;

  /// Is `Transfer-Encoding` chunked?
  bool chunked;

  /// Any and all cookies to be sent to the user.
  final List<Cookie> cookies = [];

  /// Headers that will be sent to the user.
  final Map<String, String> headers = {HttpHeaders.SERVER: 'angel'};

  /// Serializes response data into a String.
  ///
  /// The default is conversion into JSON.
  ResponseSerializer serializer = god.serialize;

  /// This response's status code.
  int statusCode = 200;

  /// Can we still write to this response?
  bool get isOpen => _isOpen;

  /// A set of UTF-8 encoded bytes that will be written to the response.
  final BytesBuilder buffer = new BytesBuilder();

  /// Sets the status code to be sent with this response.
  @Deprecated('Please use `statusCode=` instead.')
  void status(int code) {
    statusCode = code;
  }

  /// The underlying [HttpResponse] under this instance.
  final HttpResponse io;

  @deprecated
  HttpResponse get underlyingRequest {
    throw new Exception(
        '`ResponseContext#underlyingResponse` is deprecated. Please update your application to use the newer `ResponseContext#io`.');
  }

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

  ResponseContext(this.io, this.app);

  /// Set this to true if you will manually close the response.
  ///
  /// If `true`, all response finalizers will be skipped.
  bool willCloseItself = false;

  /// Sends a download as a response.
  download(File file, {String filename}) async {
    headers["Content-Disposition"] =
        'attachment; filename="${filename ?? file.path}"';
    headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);
    headers[HttpHeaders.CONTENT_LENGTH] = file.lengthSync().toString();
    buffer.add(await file.readAsBytes());
    end();
  }

  /// Prevents more data from being written to the response.
  void end() {
    _isOpen = false;
  }

  /// Sets a response header to the given value, or retrieves its value.
  @Deprecated('Please use `headers` instead.')
  header(String key, [String value]) {
    if (value == null)
      return headers[key];
    else
      headers[key] = value;
  }

  /// Serializes JSON to the response.
  void json(value) => serialize(value, contentType: ContentType.JSON);

  /// Returns a JSONP response.
  void jsonp(value, {String callbackName: "callback"}) {
    write("$callbackName(${god.serialize(value)})");
    headers[HttpHeaders.CONTENT_TYPE] = "application/javascript";
    end();
  }

  /// Renders a view to the response stream, and closes the response.
  Future render(String view, [Map data]) async {
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
    headers[HttpHeaders.LOCATION] =
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
  Future sendFile(File file,
      {int chunkSize, int sleepMs: 0, bool resumable: true}) async {
    if (!isOpen) return;

    headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);
    buffer.add(await file.readAsBytes());
    end();
  }

  /// Serializes data to the response.
  ///
  /// [contentType] can be either a [String], or a [ContentType].
  void serialize(value, {contentType}) {
    var text = serializer(value);
    write(text);
    
    if (contentType is String)
      headers[HttpHeaders.CONTENT_TYPE] = contentType;
    else if (contentType is ContentType) this.contentType = contentType;

    end();
  }

  /// Streams a file to this response.
  ///
  /// You can optionally transform the file stream with a [codec].
  Future streamFile(File file,
      {int chunkSize,
      int sleepMs: 0,
      bool resumable: true,
      Codec<List<int>, List<int>> codec}) async {
    if (!isOpen) return;

    headers[HttpHeaders.CONTENT_TYPE] = lookupMimeType(file.path);
    end();
    willCloseItself = true;

    var stream = codec != null
        ? file.openRead().transform(codec.encoder)
        : file.openRead();
    await stream.pipe(io);
  }

  /// Writes data to the response.
  void write(value, {Encoding encoding: UTF8}) {
    if (isOpen) {
      if (value is List<int>)
        buffer.add(value);
      else
        buffer.add(encoding.encode(value.toString()));
    }
  }
}
