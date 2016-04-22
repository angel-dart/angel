/// Configuration for this Angel instance.
library angel.config;

import 'dart:io';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mustache/angel_mustache.dart';
import 'routes.dart';

configureServer(Angel app) {
  app.configure(loadConfigurationFile());
  app.configure(mustache(new Directory('views')));
  app.configure(configureRoutes);
}