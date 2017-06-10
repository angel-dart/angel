/// Configuration for this Angel instance.
library angel.config;

import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'plugins/plugins.dart' as plugins;

/// This is a perfect place to include configuration and load plug-ins.
configureServer(Angel app) async {
  // Load configuration from the `config/` directory.
  //
  // See: https://github.com/angel-dart/configuration
  await app.configure(loadConfigurationFile());

  // Configure our application to render Mustache templates from the `views/` directory.
  //
  // See: https://github.com/angel-dart/mustache
  await app.configure(mustache(new Directory('views')));

  // Apply another plug-ins, i.e. ones that *you* have written.
  //
  // Typically, the plugins in `lib/src/config/plugins/plugins.dart` are plug-ins
  // that add functionality specific to your application.
  //
  // If you write a plug-in that you plan to use again, or are
  // using one created by the community, include it in
  // `lib/src/config/config.dart`.
  await plugins.configureServer(app);
}
