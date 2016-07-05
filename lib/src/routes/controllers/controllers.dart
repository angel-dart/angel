library angel.routes.controllers;

import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
part 'auth.dart';

configureServer(Angel app) async {
  await app.configure(new AuthController());
}
