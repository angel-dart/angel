/// This app's route configuration.
library angel.routes;

import 'package:angel_cors/angel_cors.dart';
import 'package:angel_errors/angel_errors.dart';
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
  // Set our application up to handle different errors.
  var errors = new ErrorHandler(handlers: {
    404: (req, res) async =>
        res.render('error', {'message': 'No file exists at ${req.path}.'}),
    500: (req, res) async => res.render('error', {'message': req.error.message})
  });

  errors.fatalErrorHandler = (AngelFatalError e) async {
    e.request.response
      ..statusCode = 500
      ..writeln('500 Internal Server Error: ${e.error}')
      ..writeln(e.stack);
    await e.request.response.close();
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
}

configureServer(Angel app) async {
  await configureBefore(app);
  await configureRoutes(app);
  await app.configure(Controllers.configureServer);
  await configureAfter(app);
}
