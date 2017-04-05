import 'dart:io';
import 'dart:collection';
import 'package:path/path.dart' as path;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mustache/src/mustache_context.dart';

class MustacheCacheController {

  /**
   * The context for which views and partials are
   * served from.
   */
  MustacheContext context;

  HashMap<String, String> viewCache = new HashMap();
  HashMap<String, String> partialCache = new HashMap();

  MustacheCacheController([this.context]);

  get_view(String viewName, Angel app) async {
    if (app.isProduction) {
      if (viewCache.containsKey(viewName)) {
        return viewCache[viewName];
      }
    }

    File viewFile = context.resolveView(viewName);

    if (await viewFile.exists()) {
      String viewTemplate = await viewFile.readAsString();
      if (app.isProduction) {
        this.viewCache[viewName] = viewTemplate;
      }
      return viewTemplate;
    } else
      throw new FileSystemException(
          'View "$viewName" was not found.', viewFile.path);
  }

  get_partial(String partialName, Angel app) {
    if (app.isProduction) {
      if (partialCache.containsKey(partialName)) {
        return partialCache[partialName];
      }
    }

    File partialFile = context.resolvePartial(partialName);

    if (partialFile.existsSync()) {
      String partialTemplate = partialFile.readAsStringSync();
      if (app.isProduction) {
        this.partialCache[partialName] = partialTemplate;
      }
      return partialTemplate;
    } else
      throw new FileSystemException(
          'View "$partialName" was not found.', partialFile.path);
  }
}
