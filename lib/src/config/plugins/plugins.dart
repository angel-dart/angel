/// Custom plugins go here.
library angel.src.config.plugins;

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'orm.dart' as orm;

Future configureServer(Angel app) async {
  // Include any plugins you have made here.
  await app.configure(orm.configureServer);
}
