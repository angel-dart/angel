library angel.routes.controllers;

import 'package:angel_framework/angel_framework.dart';
import 'auth.dart';

configureServer(Angel app) async {
  await app.configure(new AuthController());
}
