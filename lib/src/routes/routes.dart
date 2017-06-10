/// This app's route configuration.
library angel.routes;

import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'controllers/controllers.dart' as controllers;

/// Adds global middleware to the application.
///
/// Use these to apply functionality to requests before business logic is run.
///
/// More on the request lifecycle:
/// https://github.com/angel-dart/angel/wiki/Request-Lifecycle
configureBefore(Angel app) async {
  app.before.add(cors());
}

/// Put your app routes here!
///
/// See the wiki for information about routing, requests, and responses:
/// * https://github.com/angel-dart/angel/wiki/Basic-Routing
/// * https://github.com/angel-dart/angel/wiki/Requests-&-Responses
configureRoutes(Angel app) async {
  // Render `views/hello.mustache` when a user visits the application root.
  app.get('/', (req, ResponseContext res) => res.render('hello'));
}

/// Configures fallback middleware.
///
/// Use these to run generic actions on requests that were not terminated by
/// earlier request handlers.
///
/// Note that these middleware might not always run.
///
/// More on the request lifecycle: https://github.com/angel-dart/angel/wiki/Request-Lifecycle
configureAfter(Angel app) async {
  // Uncomment this to proxy over `pub serve` while in development.
  // This is a useful feature for full-stack applications, especially if you
  // are using Angular2.
  //
  // For documentation, see `package:angel_proxy`:
  // https://github.com/angel-dart/proxy
  //
  // await app.configure(new PubServeLayer());

  // Mount static server at /web or /build/web, depending on if
  // you are running in production mode. `Cache-Control` headers will also be enabled.
  //
  // Read the following two sources for documentation:
  // * https://medium.com/the-angel-framework/serving-static-files-with-the-angel-framework-2ddc7a2b84ae
  // * https://github.com/angel-dart/static
  await app.configure(new CachingVirtualDirectory());

  // Set our application up to handle different errors.
  //
  // Read the following two sources for documentation:
  // * https://github.com/angel-dart/angel/wiki/Error-Handling
  // * https://github.com/angel-dart/errors
  var errors = new ErrorHandler(handlers: {
    // Display a 404 page if no resource is found.
    404: (req, res) async =>
        res.render('error', {'message': 'No file exists at ${req.path}.'}),

    // On generic errors, give information about why the application failed.
    //
    // An `AngelHttpException` instance will be present in `req.properties`
    // as `error`.
    500: (req, res) async => res.render('error', {'message': req.error.message})
  });

  // Use a fatal error handler to attempt to resolve any issues that
  // result in Angel not being able to send the user a response.
  errors.fatalErrorHandler = (AngelFatalError e) async {
    try {
      // Manually create a request and response context.
      var req = await RequestContext.from(e.request, app);
      var res = new ResponseContext(e.request.response, app);

      // *Attempt* to render an error page.
      res.render('error', {'message': 'Internal Server Error: ${e.error}'});
      await app.sendResponse(e.request, req, res);
    } catch (_) {
      // If execution fails here, there is nothing we can do.
      stderr..writeln('Fatal error: ${e.error}')..writeln(e.stack);
    }
  };

  // Throw a 404 if no route matched the request.
  app.after.add(() => throw new AngelHttpException.notFound());

  // Handle errors when they occur, based on outgoing status code.
  // By default, requests will go through the 500 handler, unless
  // they have an outgoing 200, or their status code has a handler
  // registered.
  app.after.add(errors.middleware());

  // Pass AngelHttpExceptions through handler as well.
  //
  // Again, here is the error handling documentation:
  // * https://github.com/angel-dart/angel/wiki/Error-Handling
  // * https://github.com/angel-dart/errors
  await app.configure(errors);
}

/// Adds response finalizers to the application.
///
/// These run after every request.
///
/// See more on the request lifecycle here:
/// https://github.com/angel-dart/angel/wiki/Request-Lifecycle
configureFinalizers(Angel app) async {}

/// Adds routes to our application.
///
/// See the wiki for information about routing, requests, and responses:
/// * https://github.com/angel-dart/angel/wiki/Basic-Routing
/// * https://github.com/angel-dart/angel/wiki/Requests-&-Responses
configureServer(Angel app) async {
  // The order in which we run these plug-ins is relatively significant.
  // Try not to change it.

  // Add global middleware.
  await configureBefore(app);

  // Typically, you want to mount controllers first, after any global middleware.
  await app.configure(controllers.configureServer);

  // Next, you can add any supplemental routes.
  await configureRoutes(app);

  // Add handlers to run after requests are handled.
  //
  // See the request lifecycle docs to find out why these two
  // are separate:
  // https://github.com/angel-dart/angel/wiki/Request-Lifecycle
  await configureAfter(app);
  await configureFinalizers(app);
}
