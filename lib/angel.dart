/// Your very own web application!
library angel;

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'src/config/config.dart' as configuration;
import 'src/routes/routes.dart' as routes;
import 'src/services/services.dart' as services;
export 'src/services/services.dart';

/// Creates and configures the server instance.
Future<Angel> createServer() async {
  Angel app = new Angel();

  await app.configure(configuration.configureServer);
  await app.configure(services.configureServer);
  await app.configure(routes.configureServer);

  return app;
}