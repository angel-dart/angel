/// This app's route configuration.
library angel.routes;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';

/// Put your app routes here!
configureRoutes(Angel app) {
  app.get('/', (req, ResponseContext res) => res.render('hello'));
  app.all('*', serveStatic());

  // 404 handler
  app.after.add((RequestContext req, ResponseContext res) async {
    res.willCloseItself = true;
    res.status(404);
    res.header('Content-Type', 'text/html');
    res.underlyingResponse.write(
        await app.viewGenerator('404', {'path': req.path}));
    await res.underlyingResponse.close();
  });
}