/// Your very own web application!
library angel;

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'src/config/config.dart' show configureServer;

/// Creates and configures the server instance.
Future<Angel> createServer() async {
  Angel app = new Angel();

  await app.configure(configureServer);

  return app;
}