/// This app's route configuration.
library angel.src.routes;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/file.dart';
import 'controllers/controllers.dart' as controllers;
import '../models/greeting.dart';

/// Put your app routes here!
///
/// See the wiki for information about routing, requests, and responses:
/// * https://github.com/angel-dart/angel/wiki/Basic-Routing
/// * https://github.com/angel-dart/angel/wiki/Requests-&-Responses
AngelConfigurer configureServer(FileSystem fileSystem) {
  return (Angel app) async {
    // Typically, you want to mount controllers first, after any global middleware.
    await app.configure(controllers.configureServer);

    // Render `views/hello.jl` when a user visits the application root.
    app.get('/', (req, res) => res.render('hello'));

    app.get('/greetings', (req, res) {
      var executor = req.container.make<QueryExecutor>();
      var query = GreetingQuery();
      return query.get(executor);
    });

    app.post('/greetings', (req, res) async {
      await req.parseBody();

      if (!req.bodyAsMap.containsKey('message')) {
        throw AngelHttpException.badRequest(message: 'Missing "message".');
      } else {
        var executor = req.container.make<QueryExecutor>();
        var message = req.bodyAsMap['message'].toString();
        var query = GreetingQuery()..values.message = message;
        return await query.insert(executor);
      }
    });

    app.get('/greetings/:message', (req, res) {
      var message = req.params['message'] as String;
      var executor = req.container.make<QueryExecutor>();
      var query = GreetingQuery()..where.message.equals(message);
      return query.get(executor);
    });

    // Mount static server at web in development.
    // The `CachingVirtualDirectory` variant of `VirtualDirectory` also sends `Cache-Control` headers.
    //
    // In production, however, prefer serving static files through NGINX or a
    // similar reverse proxy.
    //
    // Read the following two sources for documentation:
    // * https://medium.com/the-angel-framework/serving-static-files-with-the-angel-framework-2ddc7a2b84ae
    // * https://github.com/angel-dart/static
    if (!app.isProduction) {
      var vDir = VirtualDirectory(
        app,
        fileSystem,
        source: fileSystem.directory('web'),
      );
      app.fallback(vDir.handleRequest);
    }

    // Throw a 404 if no route matched the request.
    app.fallback((req, res) => throw AngelHttpException.notFound());

    // Set our application up to handle different errors.
    //
    // Read the following for documentation:
    // * https://github.com/angel-dart/angel/wiki/Error-Handling

    var oldErrorHandler = app.errorHandler;
    app.errorHandler = (e, req, res) async {
      if (!req.accepts('text/html'))
        return await oldErrorHandler(e, req, res);
      else {
        if (e.statusCode == 404) {
          return await res
              .render('error', {'message': 'No file exists at ${req.uri}.'});
        }

        return await res.render('error', {'message': e.message});
      }
    };
  };
}
