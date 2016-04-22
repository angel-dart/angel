library angel_mustache;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mustache4dart/mustache4dart.dart' show render;

mustache(Directory viewsDirectory, {String fileExtension: '.mustache'}) {
  return (Angel app) {
    app.viewGenerator = (String name, [Map data]) async {
      String viewPath = name + fileExtension;
      File viewFile = new File.fromUri(
          viewsDirectory.absolute.uri.resolve(viewPath));
      if (await viewFile.exists()) {
        return render(await viewFile.readAsString(), data ?? {});
      } else throw new FileSystemException(
          'View "$name" was not found.', viewPath);
    };
  };
}