/// Your very own web application!
library angel;

import 'package:angel_framework/angel_framework.dart';
import 'src/config/config.dart' show configureServer;

/// Creates and configures the server instance.
Angel createServer() {
  Angel app = new Angel();

  app.configure(configureServer);

  return app;
}