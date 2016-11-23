library angel_framework.http.response_context;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_route/angel_route.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:mime/mime.dart';
import '../extensible.dart';
import 'angel_base.dart';
import 'controller.dart';

/// A convenience wrapper around an outgoing HTTP request.
class ResponseContext extends Extensible {
  bool _isOpen = true;

  /// The [Angel] instance that is sending a response.
  AngelBase app;

  /// Can we still write to this response?
  bool get isOpen => _isOpen;

  /// A set of UTF-8 encoded bytes that will be written to the response.
  final BytesBuilder buffer = new BytesBuilder();

  /// Sets the status code to be sent with this response.
  void status(int code) {
    io.statusCode = code;
  }

  /// The underlying [HttpResponse] under this instance.
  final HttpResponse io;

  @deprecated
  HttpResponse get underlyingRequest {
    throw new Exception(
        '`ResponseContext#underlyingResponse` is deprecated. Please update your application to use the newer `ResponseContext#io`.');
  }

  ResponseContext(this.io, this.app);

  /// Any and all cookies to be sent to the user.
  List<Cookie> get cookies => io.cookies;

  /// Set this to true if you will manually close the response.
  bool willCloseItself = false;

  /// Sends a download as a response.
  download(File file, {String filename}) async {
    header("Content-Disposition",
        'attachment; filename="${filename ?? file.path}"');
    header(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path));
    header(HttpHeaders.CONTENT_LENGTH, file.lengthSync().toString());
    buffer.add(await file.readAsBytes());
    end();
  }

  /// Prevents more data from being written to the response.
  void end() {
    _isOpen = false;
  }

  /// Sets a response header to the given value, or retrieves its value.
  header(String key, [String value]) {
    if (value == null)
      return io.headers[key];
    else
      io.headers.set(key, value);
  }

  /// Serializes JSON to the response.
  void json(value) {
    write(god.serialize(value));
    header(HttpHeaders.CONTENT_TYPE, ContentType.JSON.toString());
    end();
  }

  /// Returns a JSONP response.
  void jsonp(value, {String callbackName: "callback"}) {
    write("$callbackName(${god.serialize(value)})");
    header(HttpHeaders.CONTENT_TYPE, "application/javascript");
    end();
  }

  /// Renders a view to the response stream, and closes the response.
  Future render(String view, [Map data]) async {
    write(await app.viewGenerator(view, data));
    header(HttpHeaders.CONTENT_TYPE, ContentType.HTML.toString());
    end();
  }

  /// Redirects to user to the given URL.
  void redirect(String url, {int code: 301}) {
    header(HttpHeaders.LOCATION, url);
    status(code ?? 301);
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
    _findRoute(Route route) {
      for (Route child in route.children) {
        final resolved = _findRoute(child);

        if (resolved != null) return resolved;
      }

      return route.children
          .firstWhere((r) => r.name == name, orElse: () => null);
    }

    Route matched = _findRoute(app.root);

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

    // Todo: AngelResponseException
    if (split.length < 2)
      throw new Exception(
          "Controller redirects must take the form of 'Controller@action'. You gave: $action");

    Controller controller = app.controller(split[0]);

    if (controller == null)
      throw new Exception("Could not find a controller named '${split[0]}'");

    Route matched = controller.routeMappings[split[1]];

    if (matched == null)
      throw new Exception(
          "Controller '${split[0]}' does not contain any action named '${split[1]}'");

    redirect(matched.makeUri(params), code: code);
  }

  /// Streams a file to this response as chunked data.
  ///
  /// Useful for video sites.
  Future streamFile(File file,
      {int chunkSize, int sleepMs: 0, bool resumable: true}) async {
    if (!isOpen) return;

    header(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path));
    willCloseItself = true;
    await file.openRead().pipe(io);
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
