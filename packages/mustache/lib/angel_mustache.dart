library angel_mustache;

import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'package:mustache4dart/mustache4dart.dart' show render;
import 'package:path/path.dart' as p;
import 'src/cache.dart';
import 'src/mustache_context.dart';

mustache(Directory viewsDirectory,
    {String fileExtension: '.mustache', String partialsPath: './partials'}) {
  Directory partialsDirectory = viewsDirectory.fileSystem
      .directory(p.join(p.fromUri(viewsDirectory.uri), partialsPath));

  MustacheContext context =
      new MustacheContext(viewsDirectory, partialsDirectory, fileExtension);

  MustacheViewCache cache = new MustacheViewCache(context);

  return (Angel app) async {
    app.viewGenerator = (String name, [Map data]) async {
      var partialsProvider;
      partialsProvider = (String name) {
        String template = cache.getPartialSync(name, app);
        return render(template, data ?? {}, partial: partialsProvider);
      };

      String viewTemplate = await cache.getView(name, app);
      return await render(viewTemplate, data ?? {}, partial: partialsProvider);
    };
  };
}
