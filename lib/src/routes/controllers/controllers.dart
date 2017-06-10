library angel.routes.controllers;

import 'package:angel_common/angel_common.dart';
import 'auth.dart';

configureServer(Angel app) async {
  /// Controllers will not function unless wired to the application!
  await app.configure(new AuthController());
}
