import 'dart:async';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'package:markdown/markdown.dart';

final RegExp _braces = new RegExp(r'@?{{(((\\})|([^}]))+)}}');

/// Configures an [Angel] instance to render Markdown templates from the specified [viewsDirectory].
///
/// The default [extension] is `.md`. To search for a different file extension, provide a new one.
/// By default, an [extensionSet] is provided that renders Github-flavored Markdown. This can also be overridden.
///
/// In many cases, Markdown content will be rendered within a larger [template] that styles the entire website.
/// To wrap generated Markdown content in a template, provide a function that accepts a generated HTML String,
/// and returns a String, or a `Future<String>`.
AngelConfigurer markdown(
  Directory viewsDirectory, {
  String extension,
  ExtensionSet extensionSet,
  FutureOr<String> template(String content, Map<String, dynamic> locals),
}) {
  extension ??= '.md';
  extensionSet ??= ExtensionSet.gitHubWeb;

  return (Angel app) async {
    app.viewGenerator = (String name, [Map<String, dynamic> locals]) async {
      var file = viewsDirectory.childFile(
          viewsDirectory.fileSystem.path.setExtension(name, extension));
      var contents = await file.readAsString();

      contents = contents.replaceAllMapped(_braces, (m) {
        var text = m[0];

        if (text.startsWith('@')) {
          // Raw braces
          return text.substring(1);
        } else {
          var expr = m[1];
          var split = expr.split('.');
          var root = split[0];

          if (locals?.containsKey(root) != true)
            throw new UnimplementedError(
                'Expected a local named "$root", but none was provided. Expression text: "$text"');

          return _resolveDotNotation(split, locals[root]).toString();
        }
      });

      var html = markdownToHtml(contents, extensionSet: extensionSet);
      if (template != null) html = await template(html, locals ?? {});
      return html;
    };
  };
}

_resolveDotNotation(List<String> split, target) {
  if (split.length == 1) return target;

  InstanceMirror mirror = reflect(target);

  for (int i = 1; i < split.length; i++) {
    mirror = mirror.getField(new Symbol(split[i]));
  }

  return mirror.reflectee;
}
