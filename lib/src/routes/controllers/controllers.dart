library angel.routes.controllers;

import 'package:angel_common/angel_common.dart';
import 'auth.dart';

configureServer(Angel app) async {
  await app.configure(new AuthController());
}
