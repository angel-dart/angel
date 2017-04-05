library angel_mustache;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mustache4dart/mustache4dart.dart' show render;
import 'package:angel_mustache/src/cache.dart';

mustache(Directory viewsDirectory,
    {String fileExtension: '.mustache', String partialsPath: './partials'}) {

  Directory partialsDirectory = new Directory.fromUri(
  viewsDirectory.uri.resolve(partialsPath));
  
  MustacheCacheController cache = new MustacheCacheController(
    viewsDirectory, partialsDirectory, fileExtension);

  return (Angel app) async {
    app.viewGenerator = (String name, [Map data]) async {
      var partialsProvider;
      partialsProvider = (String name) {
          String template = cache.get_partial(name, app);
          return render(template, data ?? {},
              partial: partialsProvider);
      };

      String viewTemplate = await cache.get_view(name, app);
      return render(viewTemplate, data ?? {}, partial: partialsProvider);
    };
  };
}