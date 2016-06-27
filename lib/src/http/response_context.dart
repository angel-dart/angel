part of angel_framework.http;

/// A function that asynchronously generates a view from the given path and data.
typedef Future<String> ViewGenerator(String path, [Map data]);

/// A convenience wrapper around an outgoing HTTP request.
class ResponseContext extends Extensible {
  /// The [Angel] instance that is sending a response.
  Angel app;

  /// Can we still write to this response?
  bool isOpen = true;

  /// A set of UTF-8 encoded bytes that will be written to the response.
  List<List<int>> responseData = [];

  /// Sets the status code to be sent with this response.
  status(int code) {
    underlyingResponse.statusCode = code;
  }

  /// The underlying [HttpResponse] under this instance.
  HttpResponse underlyingResponse;

  ResponseContext(this.underlyingResponse);

  /// Any and all cookies to be sent to the user.
  List<Cookie> get cookies => underlyingResponse.cookies;

  /// Set this to true if you will manually close the response.
  bool willCloseItself = false;

  /// Sends a download as a response.
  download(File file, {String filename}) {
    header("Content-Disposition",
        'Content-Disposition: attachment; filename="${filename ?? file.path}"');
    header(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path));
    header(HttpHeaders.CONTENT_LENGTH, file.lengthSync().toString());
    responseData.add(file.readAsBytesSync());
  }

  /// Prevents more data from being written to the response.
  end() => isOpen = false;

  /// Sets a response header to the given value, or retrieves its value.
  header(String key, [String value]) {
    if (value == null) return underlyingResponse.headers[key];
    else underlyingResponse.headers.set(key, value);
  }

  /// Serializes JSON to the response.
  json(value) {
    write(god.serialize(value));
    header(HttpHeaders.CONTENT_TYPE, ContentType.JSON.toString());
    end();
  }

  /// Returns a JSONP response.
  jsonp(value, {String callbackName: "callback"}) {
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
  redirect(String url, {int code: 301}) {
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
        Click <a href="$url"></a> if you are not automatically redirected...
        <script>
          window.location = "$url";
        </script>
      </body>
    </html>
    ''');
    end();
  }

  /// Redirects to the given named [Route].
  redirectTo(String name, [Map params, int code]) {
    Route matched = app.routes.firstWhere((Route route) => route.name == name);
    if (matched != null) {
      return redirect(matched.makeUri(params), code: code);
    }

    throw new ArgumentError.notNull('Route to redirect to ($name)');
  }

  /// Redirects to the given [Controller] action.
  redirectToAction(String action, [Map params, int code]) {
    // UserController@show
    List<String> split = action.split("@");

    if (split.length < 2)
      throw new Exception("Controller redirects must take the form of 'Controller@action'. You gave: $action");

    Controller controller = app.controller(split[0]);

    if (controller == null)
      throw new Exception("Could not find a controller named '${split[0]}'");

    Route matched = controller._mappings[split[1]];

    if (matched == null)
      throw new Exception("Controller '${split[0]}' does not contain any action named '${split[1]}'");

    return redirect(matched.makeUri(params), code: code);
  }

  /// Streams a file to this response as chunked data.
  ///
  /// Useful for video sites.
  streamFile(File file,
      {int chunkSize, int sleepMs: 0, bool resumable: true}) async {
    if (!isOpen) return;

    header(HttpHeaders.CONTENT_TYPE, lookupMimeType(file.path));
    willCloseItself = true;
    await file.openRead().pipe(underlyingResponse);
    /*await chunked(file.openRead(), chunkSize: chunkSize,
        sleepMs: sleepMs,
        resumable: resumable);*/
  }

  /// Writes data to the response.
  write(value) {
    if (isOpen)
      responseData.add(UTF8.encode(value.toString()));
  }

  /// Magically transforms an [HttpResponse] object into a ResponseContext.
  static Future<ResponseContext> from
      (HttpResponse response, Angel app) async
  {
    ResponseContext context = new ResponseContext(response);
    context.app = app;
    return context;
  }
}