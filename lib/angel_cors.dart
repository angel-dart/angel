/// Angel CORS middleware.
library angel_cors;

import 'package:angel_framework/angel_framework.dart';
import 'src/cors_options.dart';
export 'src/cors_options.dart';

/// Determines if a request origin is CORS-able.
typedef bool CorsFilter(String origin);

bool _isOriginAllowed(String origin, allowedOrigin) {
  if (allowedOrigin is List) {
    return allowedOrigin.any((x) => _isOriginAllowed(origin, x));
  } else if (allowedOrigin is String) {
    return origin == allowedOrigin;
  } else if (allowedOrigin is RegExp) {
    return allowedOrigin.hasMatch(origin);
  } else if (allowedOrigin is CorsFilter) {
    return allowedOrigin(origin);
  } else {
    return allowedOrigin != false;
  }
}

/// Applies the given [CorsOptions].
RequestMiddleware cors([CorsOptions options]) {
  final opts = options ?? new CorsOptions();

  return (RequestContext req, ResponseContext res) async {
    // Access-Control-Allow-Credentials
    if (opts.credentials == true) {
      res.heades['Access-Control-Allow-Credentials'] = 'true';
    }

    // Access-Control-Allow-Headers
    if (req.method == 'OPTIONS' && opts.allowedHeaders.isNotEmpty) {
      res.headers['Access-Control-Allow-Headers'] =
          opts.allowedHeaders.join(',');
    } else if (req.method == 'OPTIONS') {
      res.headers['Access-Control-Allow-Headers'] =
          req.headers.value('Access-Control-Allow-Headers');
    }

    // Access-Control-Expose-Headers
    if (opts.exposedHeaders.isNotEmpty) {
      res.headers['Access-Control-Expose-Headers'] =
          opts.exposedHeaders.join(',');
    }

    // Access-Control-Allow-Methods
    if (req.method == 'OPTIONS' && opts.methods.isNotEmpty) {
      res.headers['Access-Control-Allow-Methods'] = opts.methods.join(',');
    }

    // Access-Control-Max-Age
    if (req.method == 'OPTIONS' && opts.maxAge != null) {
      res.headers['Access-Control-Max-Age'] = opts.maxAge.toString();
    }

    // Access-Control-Allow-Origin
    if (opts.origin == false || opts.origin == '*') {
      res.headers['Access-Control-Allow-Origin'] = '*';
    } else if (opts.origin is String) {
      res
        ..headers['Access-Control-Allow-Origin'] = opts.origin
        ..headers['Vary'] = 'Origin';
    } else {
      bool isAllowed =
          _isOriginAllowed(req.headers.value('Origin'), opts.origin);

      res.headers['Access-Control-Allow-Origin'] =
          isAllowed ? req.headers.value('Origin') : false.toString();

      if (isAllowed) {
        res.headers['Vary'] = 'Origin';
      }
    }

    return req.method != 'OPTIONS' || opts.preflightContinue;
  };
}
