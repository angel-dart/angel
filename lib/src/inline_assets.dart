import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:dart2_constant/convert.dart';
import 'package:file/file.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

VirtualDirectory inlineAssets(VirtualDirectory vDir) => new _InlineAssets(vDir);

class _InlineAssets extends VirtualDirectory {
  final VirtualDirectory inner;

  _InlineAssets(this.inner)
      : super(inner.app, inner.fileSystem,
            source: inner.source,
            indexFileNames: inner.indexFileNames,
            publicPath: inner.publicPath,
            callback: inner.callback,
            allowDirectoryListing: inner.allowDirectoryListing);

  @override
  Future<bool> serveFile(
      File file, FileStat stat, RequestContext req, ResponseContext res) async {
    if (p.extension(file.path) == '.html') {
      var contents = await file.readAsString();
      var doc = html.parse(contents, sourceUrl: file.uri.toString());

      var linksWithRel = doc.head
              ?.getElementsByTagName('link')
              ?.where((link) => link.attributes['rel'] == 'stylesheet') ??
          <html.Element>[];

      for (var link in linksWithRel) {
        if (link.attributes.containsKey('data-no-inline')) {
          link.attributes.remove('data-no-inline');
        } else {
          var uri = Uri.parse(link.attributes['href']);

          if (uri.scheme.isEmpty) {
            var styleFile = inner.source.childFile(uri.path);

            if (await styleFile.exists()) {
              var style = new html.Element.tag('style')
                ..innerHtml = await styleFile.readAsString();
              link.replaceWith(style);
            }
          }
        }
      }

      var scripts = doc
          .getElementsByTagName('script')
          .where((script) => script.attributes.containsKey('src'));

      for (var script in scripts) {
        if (script.attributes.containsKey('data-no-inline')) {
          script.attributes.remove('data-no-inline');
        } else {
          var uri = Uri.parse(script.attributes['src']);

          if (uri.scheme.isEmpty) {
            var scriptFile = inner.source.childFile(uri.path);
            if (await scriptFile.exists()) {
              script.attributes.remove('src');
              script.innerHtml = await scriptFile.readAsString();
            }
          }
        }
      }

      res
        ..headers['content-type'] = 'text/html; charset=utf8'
        ..buffer.add(utf8.encode(doc.outerHtml));
      return false;
    } else {
      return await inner.serveFile(file, stat, req, res);
    }
  }
}
