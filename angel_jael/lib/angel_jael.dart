import 'package:angel_framework/angel_framework.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:file/file.dart';
import 'package:jael/jael.dart';
import 'package:jael_preprocessor/jael_preprocessor.dart';
import 'package:symbol_table/symbol_table.dart';

/// Configures an Angel server to use Jael to render templates.
///
/// To enable "minified" output, you need to override the [createBuffer] function,
/// to instantiate a [CodeBuffer] that emits no spaces or line breaks.
///
/// To apply additional transforms to parsed documents, provide a set of [patch] functions.
AngelConfigurer jael(Directory viewsDirectory,
    {String fileExtension,
    bool strictResolution: false,
    bool cacheViews: false,
    Iterable<Patcher> patch,
    bool asDSX: false,
    CodeBuffer createBuffer()}) {
  var cache = <String, Document>{};
  fileExtension ??= '.jael';
  createBuffer ??= () => new CodeBuffer();

  return (Angel app) async {
    app.viewGenerator = (String name, [Map locals]) async {
      var errors = <JaelError>[];
      Document processed;

      if (cacheViews == true && cache.containsKey(name)) {
        processed = cache[name];
      } else {
        var file = viewsDirectory.childFile(name + fileExtension);
        var contents = await file.readAsString();
        var doc = parseDocument(contents,
            sourceUrl: file.uri, asDSX: asDSX == true, onError: errors.add);
        processed = doc;

        try {
          processed = await resolve(doc, viewsDirectory,
              patch: patch, onError: errors.add);
        } catch (_) {
          // Ignore these errors, so that we can show syntax errors.
        }

        if (cacheViews == true) {
          cache[name] = processed;
        }
      }

      var buf = createBuffer();
      var scope = new SymbolTable(
          values: locals?.keys?.fold<Map<String, dynamic>>(<String, dynamic>{},
                  (out, k) => out..[k.toString()] = locals[k]) ??
              <String, dynamic>{});

      if (errors.isEmpty) {
        try {
          const Renderer().render(processed, buf, scope,
              strictResolution: strictResolution == true);
          return buf.toString();
        } on JaelError catch (e) {
          errors.add(e);
        }
      }

      Renderer.errorDocument(errors, buf..clear());
      return buf.toString();
    };
  };
}
