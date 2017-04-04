import 'dart:io';
import 'dart:collection';

import 'package:angel_framework/angel_framework.dart';

class MustacheCacheController {
  HashMap<String, String> viewCache = new HashMap();
  HashMap<String, String> partialCache = new HashMap();

  /**
   * The directory of the mustache views
   */
  Directory viewDirectory;

  /**
   * The directory of mustache partials
   */
  Directory partialsDirectory;

  /**
   * Default file extension associated with a view file
   */
  String fileExtension;

  MustacheCacheController(
      [this.viewDirectory, this.partialsDirectory, this.fileExtension]);

  get_view(String viewName, Angel app) async {
    if (app.isProduction) {
      if (viewCache.containsKey(viewName)) {
        return viewCache[viewName];
      }
    }

    String viewPath = viewName + this.fileExtension;
    File viewFile =
        new File.fromUri(this.viewDirectory.absolute.uri.resolve(viewPath));

    if (await viewFile.exists()) {
      String viewTemplate = await viewFile.readAsString();
      if (app.isProduction) {
        this.viewCache[viewName] = viewTemplate;
      }
      return viewTemplate;
    } else
      throw new FileSystemException(
          'View "$viewName" was not found.', viewPath);
  }

  get_partial(String partialName, Angel app) {
    if (app.isProduction) {
      if (partialCache.containsKey(partialName)) {
        return partialCache[partialName];
      }
    }

    String viewPath = partialName + this.fileExtension;
    File viewFile =
        new File.fromUri(partialsDirectory.absolute.uri.resolve(viewPath));

    if (viewFile.existsSync()) {
      String partialTemplate = viewFile.readAsStringSync();
      if (app.isProduction) {
        this.partialCache[partialName] = partialTemplate;
      }
      return partialTemplate;
    } else
      throw new FileSystemException(
          'View "$partialName" was not found.', viewPath);
  }
}
