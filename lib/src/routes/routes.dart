/// This app's route configuration.
library angel.routes;

import 'package:angel_cors/angel_cors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_proxy/angel_proxy.dart';
import 'package:angel_static/angel_static.dart';
import 'controllers/controllers.dart' as Controllers;

configureBefore(Angel app) async {
  app.before.add(cors());
}

/// Put your app routes here!
configureRoutes(Angel app) async {
  app.get('/', (req, ResponseContext res) => res.render('hello'));
  await app.configure(new PubServeLayer());
  await app.configure(new VirtualDirectory());
}

configureAfter(Angel app) async {
  // 404 handler
  app.after.add((req, ResponseContext res) async {
    throw new AngelHttpException.NotFound();
  });

  // Default error handler
  app.onError(
      (e, req, res) async => res.render("error", {"message": e.message}));
}

configureServer(Angel app) async {
  await configureBefore(app);
  await configureRoutes(app);
  await app.configure(Controllers.configureServer);
  await configureAfter(app);
}
