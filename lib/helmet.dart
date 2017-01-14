library angel_security.helmet;

import 'package:angel_framework/angel_framework.dart';

/// A collection of 11 middleware and handlers to help secure your application
/// using HTTP headers.
AngelConfigurer helmet() {
  throw new Exception("Helmet isn't ready just yet! ;)");

  return (Angel app) async {
    app.before.add(waterfall([
      contentSecurityPolicy(),
      dnsPrefetchControl(),
      frameguard(),
      hpkp(),
      hsts(),
      ieNoOpen(),
      noCache(),
      noSniff(),
      referrerPolicy(),
      xssFilter()
    ]));

    app.responseFinalizers.addAll([hidePoweredBy]);
  };
}

RequestMiddleware contentSecurityPolicy() {}

RequestMiddleware dnsPrefetchControl() {}

RequestMiddleware frameguard() {}

RequestMiddleware hidePoweredBy() {}

RequestMiddleware hpkp() {}

RequestMiddleware hsts() {}

RequestMiddleware ieNoOpen() {}

RequestMiddleware noCache() {}

RequestMiddleware noSniff() {}

RequestMiddleware referrerPolicy() {}

RequestMiddleware xssFilter() {}
