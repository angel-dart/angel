import 'package:angel_framework/angel_framework.dart';
import 'package:jinja/jinja.dart';

/// Configures an Angel server to use Jinja2 to render templates.
///
/// By default, templates are loaded from the filesystem;
/// pass your own [createLoader] callback to override this.
///
/// All options other than [createLoader] are passed to either [FileSystemLoader]
/// or [Environment].
AngelConfigurer jinja({
  Iterable<String> ext = const ['html'],
  String path = 'lib/src/templates',
  bool followLinks = true,
  String stmtOpen = '{%',
  String stmtClose = '%}',
  String varOpen = '{{',
  String varClose = '}}',
  String commentOpen = '{#',
  String commentClose = '#}',
  defaultValue,
  bool autoReload = true,
  Map<String, Function> filters = const <String, Function>{},
  Map<String, Function> tests = const <String, Function>{},
  Loader Function() createLoader,
}) {
  return (app) {
    createLoader ??= () {
      return FileSystemLoader(
        ext: ext.toList(),
        path: path,
        followLinks: followLinks,
      );
    };
    var env = Environment(
      loader: createLoader(),
      stmtOpen: stmtOpen,
      stmtClose: stmtClose,
      varOpen: varOpen,
      varClose: varClose,
      commentOpen: commentOpen,
      commentClose: commentClose,
      defaultValue: defaultValue,
      autoReload: autoReload,
      filters: filters,
      tests: tests,
    );

    app.viewGenerator = (path, [values]) {
      return env.getTemplate(path).render(values);
    };
  };
}
