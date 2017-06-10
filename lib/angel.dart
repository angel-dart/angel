/// Your very own web application!
library angel;

import 'dart:async';
import 'package:angel_common/angel_common.dart';
import 'src/config/config.dart' as configuration;
import 'src/routes/routes.dart' as routes;
import 'src/services/services.dart' as services;

/// Creates and configures the server instance.
Future<Angel> createServer() async {
  /// Passing `startShared` to the constructor allows us to start multiple
  /// instances of our application concurrently, listening on a single port.
  ///
  /// This effectively lets us multi-thread the application.
  var app = new Angel.custom(startShared);

  /// Set up our application, using three plug-ins defined with this project.
  await app.configure(configuration.configureServer);
  await app.configure(services.configureServer);
  await app.configure(routes.configureServer);

  return app;
}
