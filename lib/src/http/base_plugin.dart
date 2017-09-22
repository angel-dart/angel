library angel_framework.http.base_plugin;

import 'dart:async';
import 'server.dart';

abstract class AngelPlugin {
  Future call(Angel app);
}
