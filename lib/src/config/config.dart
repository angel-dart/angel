/// Configuration for this Angel instance.
library angel.config;

import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'plugins/plugins.dart' as plugins;

/// This is a perfect place to include configuration and load plug-ins.
configureServer(Angel app) async {
  await app.configure(loadConfigurationFile());
  await app.configure(mustache(new Directory('views')));
  await plugins.configureServer(app);
}
