import 'dart:async';
import 'package:angel_cors/angel_cors.dart';
import 'package:angel_framework/angel_framework.dart';

Future configureServer(Angel app) async {
  // The default options will allow CORS for any request.
  // Combined with `fallback`, you can enable CORS application-wide.
  app.fallback(cors());

  // You can also enable CORS for a single route.
  app.get(
    '/my_api',
    chain([
      cors(),
      (req, res) {
        // Request handling logic here...
      }
    ]),
  );

  // Likewise, you can apply CORS to a group.
  app.chain([cors()]).group('/api', (router) {
    router.get('/version', (req, res) => 'v0');
  });

  // Of course, you can configure CORS.
  // The following is just a subset of the available options;
  app.fallback(cors(
    CorsOptions(
      origin: 'https://pub.dartlang.org', successStatus: 200, // default 204
      allowedHeaders: ['POST'],
      preflightContinue: false, // default false
    ),
  ));

  // You can specify the origin in different ways:
  CorsOptions(origin: 'https://pub.dartlang.org');
  CorsOptions(origin: ['https://example.org', 'http://foo.bar']);
  CorsOptions(origin: RegExp(r'^foo\.[^$]+'));
  CorsOptions(origin: (String s) => s.length == 4);

  // Lastly, you can dynamically configure CORS:
  app.fallback(dynamicCors((req, res) {
    return CorsOptions(
      origin: [
        req.headers.value('origin') ?? 'https://pub.dartlang.org',
        RegExp(r'\.com$'),
      ],
    );
  }));
}
