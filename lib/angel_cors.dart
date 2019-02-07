/// Angel CORS middleware.
library angel_cors;

import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'src/cors_options.dart';
export 'src/cors_options.dart';

/// Determines if a request origin is CORS-able.
typedef bool _CorsFilter(String origin);

bool _isOriginAllowed(String origin, [allowedOrigin]) {
  allowedOrigin ??= [];
  if (allowedOrigin is Iterable) {
    return allowedOrigin.any((x) => _isOriginAllowed(origin, x));
  } else if (allowedOrigin is String) {
    return origin == allowedOrigin;
  } else if (allowedOrigin is RegExp) {
    return origin != null && allowedOrigin.hasMatch(origin);
  } else if (origin != null && allowedOrigin is _CorsFilter) {
    return allowedOrigin(origin);
  } else {
    return allowedOrigin != false;
  }
}

/// On-the-fly configures the [cors] handler. Use this when the context of the surrounding request
/// is necessary to decide how to handle an incoming request.
Future<bool> Function(RequestContext, ResponseContext) dynamicCors(
    FutureOr<CorsOptions> Function(RequestContext, ResponseContext) f) {
  return (req, res) async {
    var opts = await f(req, res);
    var handler = cors(opts);
    return await handler(req, res);
  };
}

/// Applies the given [CorsOptions].
Future<bool> Function(RequestContext, ResponseContext) cors(
    [CorsOptions options]) {
  options ??= CorsOptions();

  return (req, res) async {
    // access-control-allow-credentials
    if (options.credentials == true) {
      res.headers['access-control-allow-credentials'] = 'true';
    }

    // access-control-allow-headers
    if (req.method == 'OPTIONS' && options.allowedHeaders.isNotEmpty) {
      res.headers['access-control-allow-headers'] =
          options.allowedHeaders.join(',');
    } else if (req.headers['access-control-request-headers'] != null) {
      res.headers['access-control-allow-headers'] =
          req.headers.value('access-control-request-headers');
    }

    // access-control-expose-headers
    if (options.exposedHeaders.isNotEmpty) {
      res.headers['access-control-expose-headers'] =
          options.exposedHeaders.join(',');
    }

    // access-control-allow-methods
    if (req.method == 'OPTIONS' && options.methods.isNotEmpty) {
      res.headers['access-control-allow-methods'] = options.methods.join(',');
    }

    // access-control-max-age
    if (req.method == 'OPTIONS' && options.maxAge != null) {
      res.headers['access-control-max-age'] = options.maxAge.toString();
    }

    // access-control-allow-origin
    if (options.origin == false || options.origin == '*') {
      res.headers['access-control-allow-origin'] = '*';
    } else if (options.origin is String) {
      res
        ..headers['access-control-allow-origin'] = options.origin as String
        ..headers['vary'] = 'origin';
    } else {
      bool isAllowed =
          _isOriginAllowed(req.headers.value('origin'), options.origin);

      res.headers['access-control-allow-origin'] =
          isAllowed ? req.headers.value('origin') : false.toString();

      if (isAllowed) {
        res.headers['vary'] = 'origin';
      }
    }

    if (req.method != 'OPTIONS') return true;
    res.statusCode = options.successStatus ?? 204;
    res.contentLength = 0;
    await res.close();
    return options.preflightContinue;
  };
}
