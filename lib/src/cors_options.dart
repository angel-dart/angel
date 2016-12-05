/// CORS configuration options.
/// 
/// The default configuration is the equivalent of:
///
///```json
///{
///  "origin": "*",
///  "methods": "GET,HEAD,PUT,PATCH,POST,DELETE",
///  "preflightContinue": false
///}
/// ```
class CorsOptions {
  /// Configures the **Access-Control-Allow-Headers** CORS header. Expects a comma-delimited string (ex: 'Content-Type,Authorization') or an array (ex: `['Content-Type', 'Authorization']`). If not specified, defaults to reflecting the headers specified in the request's **Access-Control-Request-Headers** header.
  final List<String> allowedHeaders = [];

  /// Configures the **Access-Control-Allow-Credentials** CORS header. Set to `true` to pass the header, otherwise it is omitted.
  bool credentials;

  /// Configures the **Access-Control-Expose-Headers** CORS header. Expects a comma-delimited string (ex: 'Content-Range,X-Content-Range') or an array (ex: `['Content-Range', 'X-Content-Range']`). If not specified, no custom headers are exposed.
  final List<String> exposedHeaders = [];

  /// Configures the **Access-Control-Max-Age** CORS header. Set to an integer to pass the header, otherwise it is omitted.
  ///
  /// Default: `null`
  int maxAge = null;

  /// Configures the **Access-Control-Allow-Methods** CORS header. Expects a comma-delimited string (ex: 'GET,PUT,POST') or an array (ex: `['GET', 'PUT', 'POST']`).
  ///
  /// Default: `['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE˝']`
  final List<String> methods = [];

  /// Configures the **Access-Control-Allow-Origin** CORS header.
  /// Possible values:
  /// - `Boolean` - set `origin` to `true` to reflect the [request origin](http://tools.ietf.org/html/draft-abarth-origin-09), as defined by `req.header('Origin')`, or set it to `false` to disable CORS.
  /// - `String` - set `origin` to a specific origin. For example if you set it to `"http://example.com"` only requests from "http://example.com" will be allowed.
  ///  - `RegExp` - set `origin` to a regular expression pattern which will be used to test the request origin. If it's a match, the request origin will be reflected. For example the pattern `/example\.com$/` will reflect any request that is coming from an origin ending with "example.com".
  /// - `Array` - set `origin` to an array of valid origins. Each origin can be a `String` or a `RegExp`. For example `["http://example1.com", /\.example2\.com$/]` will accept any request from "http://example1.com" or from a subdomain of "example2.com".
  /// - `Function` - set `origin` to a function implementing some custom logic. The function takes the request origin as the first parameter and a callback (which expects the signature `err [object], allow [bool]`) as the second.
  ///
  /// Default: `'*'`
  var origin;

  /// Pass the CORS preflight response to the next handler.
  ///
  /// Default: `false`
  bool preflightContinue;

  CorsOptions(
      {List<String> allowedHeaders: const [],
      this.credentials,
      this.maxAge,
      List<String> methods: const [
        'GET',
        'HEAD',
        'PUT',
        'PATCH',
        'POST',
        'DELETE˝'
      ],
      this.origin: '*',
      this.preflightContinue: false,
      List<String> exposedHeaders: const []}) {
    if (allowedHeaders != null) this.allowedHeaders.addAll(allowedHeaders);

    if (methods != null) this.methods.addAll(methods);

    if (exposedHeaders != null) this.exposedHeaders.addAll(exposedHeaders);
  }
}
