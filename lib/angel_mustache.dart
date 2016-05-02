library angel_mustache;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mustache4dart/mustache4dart.dart' show render;

mustache(Directory viewsDirectory,
    {String fileExtension: '.mustache', String partialsPath: './partials'}) {
  Directory partialsDirectory = new Directory.fromUri(
      viewsDirectory.uri.resolve(partialsPath));
  return (Angel app) async {
    app.viewGenerator = (String name, [Map data]) async {
      var partialsProvider;
      partialsProvider = (String name) {
        String viewPath = name + fileExtension;
        File viewFile = new File.fromUri(
            partialsDirectory.absolute.uri.resolve(viewPath));
        if (viewFile.existsSync()) {
          return render(viewFile.readAsStringSync(), data ?? {},
              partial: partialsProvider);
        } else throw new FileSystemException(
            'View "$name" was not found.', viewPath);
      };

      String viewPath = name + fileExtension;
      File viewFile = new File.fromUri(
          viewsDirectory.absolute.uri.resolve(viewPath));
      if (await viewFile.exists()) {
        return render(await viewFile.readAsString(), data ?? {},
            partial: partialsProvider);
      } else throw new FileSystemException(
          'View "$name" was not found.', viewPath);
    };
  };
}