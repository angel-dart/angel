import 'dart:async';

import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/local.dart';

Future<void> main() async {
  var app = Angel();
  var fs = const LocalFileSystem();
  await app.configure(configuration(fs));
}
