import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/file.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

/// Inlines assets into buffered responses, resolving paths from an [assetDirectory].
///
/// In any `.html` file sent down, `link` and `script` elements that point to internal resources
/// will have the contents of said file read, and inlined into the HTML page itself.
///
/// In this case, "internal resources" refers to a URI *without* a scheme, i.e. `/site.css` or
/// `foo/bar/baz.js`.
RequestHandler inlineAssets(Directory assetDirectory) {
  return (req, res) {
    if (!res.isOpen ||
        !res.isBuffered ||
        res.contentType.mimeType != 'text/html') {
      return new Future<bool>.value(true);
    } else {
      var doc = html.parse(utf8.decode(res.buffer.takeBytes()));
      return inlineAssetsIntoDocument(doc, assetDirectory).then((_) {
        res.buffer.add(utf8.encode(doc.outerHtml));
        return false;
      });
    }
  };
}

/// Wraps a `VirtualDirectory` to patch the way it sends
/// `.html` files.
///
/// In any `.html` file sent down, `link` and `script` elements that point to internal resources
/// will have the contents of said file read, and inlined into the HTML page itself.
///
/// In this case, "internal resources" refers to a URI *without* a scheme, i.e. `/site.css` or
/// `foo/bar/baz.js`.
VirtualDirectory inlineAssetsFromVirtualDirectory(VirtualDirectory vDir) =>
    new _InlineAssets(vDir);

/// Replaces `link` and `script` tags within a [doc] with the static contents they would otherwise trigger an HTTP request to.
///
/// Powers both [inlineAssets] and [inlineAssetsFromVirtualDirectory].
Future inlineAssetsIntoDocument(
    html.Document doc, Directory assetDirectory) async {
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
        var styleFile = assetDirectory.childFile(uri.path);

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
        var scriptFile = assetDirectory.childFile(uri.path);
        if (await scriptFile.exists()) {
          script.attributes.remove('src');
          script.innerHtml = await scriptFile.readAsString();
        }
      }
    }
  }
}

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
      await inlineAssetsIntoDocument(doc, inner.source);

      res
        ..headers['content-type'] = 'text/html; charset=utf8'
        ..add(utf8.encode(doc.outerHtml));
      return false;
    } else {
      return await inner.serveFile(file, stat, req, res);
    }
  }
}
