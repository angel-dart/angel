/// This app's route configuration.
library angel.routes;

import 'package:angel_common/angel_common.dart';
import 'controllers/controllers.dart' as controllers;

configureBefore(Angel app) async {
  app.before.add(cors());
}

/// Put your app routes here!
configureRoutes(Angel app) async {
  app.get('/', (req, ResponseContext res) => res.render('hello'));
}

configureAfter(Angel app) async {
  // Uncomment this to proxy over pub serve while in development:
  // await app.configure(new PubServeLayer());
  
  // Static server at /web or /build/web, depending on if in production
  //
  // In production, `Cache-Control` headers will also be enabled.
  await app.configure(new CachingVirtualDirectory());

  // Set our application up to handle different errors.
  var errors = new ErrorHandler(handlers: {
    404: (req, res) async =>
        res.render('error', {'message': 'No file exists at ${req.path}.'}),
    500: (req, res) async => res.render('error', {'message': req.error.message})
  });

  errors.fatalErrorHandler = (AngelFatalError e) async {
    var req = await RequestContext.from(e.request, app);
    var res = new ResponseContext(e.request.response, app);
    res.render('error', {'message': 'Internal Server Error: ${e.error}'});
    await app.sendResponse(e.request, req, res);
  };

  // Throw a 404 if no route matched the request
  app.after.add(errors.throwError());

  // Handle errors when they occur, based on outgoing status code.
  // By default, requests will go through the 500 handler, unless
  // they have an outgoing 200, or their status code has a handler
  // registered.
  app.after.add(errors.middleware());

  // Pass AngelHttpExceptions through handler as well
  await app.configure(errors);

  // Compress via GZIP
  // Ideally you'll run this on a `multiserver` instance, but if not,
  // feel free to knock yourself out!
  //
  // app.responseFinalizers.add(gzip());
}

configureServer(Angel app) async {
  await configureBefore(app);
  await app.configure(controllers.configureServer);
  await configureRoutes(app);
  await configureAfter(app);
}
