import 'dart:async';
import 'package:file/file.dart';
import 'package:jael/jael.dart';

/// Expands all `block[name]` tags within the template, replacing them with the correct content.
Future<Document> resolve(Document document, Directory currentDirectory,
    {void onError(JaelError error)}) async {
  onError ?? (e) => throw e;

  // Resolve all includes...
  var includesResolved =
      await resolveIncludes(document, currentDirectory, onError);

  if (includesResolved.root.tagName.name != 'extend') return includesResolved;

  var element = includesResolved.root;
  var attr = element.attributes
      .firstWhere((a) => a.name.name == 'src', orElse: () => null);
  if (attr == null) {
    onError(new JaelError(JaelErrorSeverity.warning,
        'Missing "src" attribute in "extend" tag.', element.tagName.span));
    return null;
  } else if (attr.value is! StringLiteral) {
    onError(new JaelError(
        JaelErrorSeverity.warning,
        'The "src" attribute in an "extend" tag must be a string literal.',
        element.tagName.span));
    return null;
  } else {
    var src = (attr.value as StringLiteral).value;
    var file =
        currentDirectory.fileSystem.file(currentDirectory.uri.resolve(src));
    var contents = await file.readAsString();
    var doc = parseDocument(contents, sourceUrl: file.uri, onError: onError);
    var processed = await resolve(
        doc, currentDirectory.fileSystem.directory(file.dirname),
        onError: onError);

    Map<String, Element> blocks = {};
    var blockElements = element.children
        .where((e) => e is Element && e.tagName.name == 'block');

    for (Element blockElement in blockElements) {
      var nameAttr = blockElement.attributes
          .firstWhere((a) => a.name.name == 'name', orElse: () => null);
      if (nameAttr == null) {
        onError(new JaelError(JaelErrorSeverity.warning,
            'Missing "name" attribute in "block" tag.', blockElement.span));
      } else if (nameAttr.value is! StringLiteral) {
        onError(new JaelError(
            JaelErrorSeverity.warning,
            'The "name" attribute in an "block" tag must be a string literal.',
            nameAttr.span));
      } else {
        var name = (nameAttr.value as StringLiteral).value;
        blocks[name] = blockElement;
      }
    }

    var blocksExpanded =
        await _expandBlocks(processed.root, blocks, currentDirectory, onError);
    return new Document(document.doctype ?? processed.doctype, blocksExpanded);
  }
}

Future<Element> _expandBlocks(Element element, Map<String, Element> blocks,
    Directory currentDirectory, void onError(JaelError error)) async {
  if (element is SelfClosingElement)
    return element;
  else if (element is RegularElement) {
    if (element.children.isEmpty) return element;

    List<ElementChild> expanded = [];

    for (var child in element.children) {
      if (child is Element) {
        if (child is SelfClosingElement)
          expanded.add(child);
        else if (child is RegularElement) {
          if (child.tagName.name != 'block') {
            expanded.add(child);
          } else {
            var nameAttr =
                child.attributes.firstWhere((a) => a.name.name == 'name', orElse: () => null);
            if (nameAttr == null) {
              onError(new JaelError(
                  JaelErrorSeverity.warning,
                  'Missing "name" attribute in "block" tag.',
                  child.span));
            } else if (nameAttr.value is! StringLiteral) {
              onError(new JaelError(
                  JaelErrorSeverity.warning,
                  'The "name" attribute in an "block" tag must be a string literal.',
                  nameAttr.span));
            }

            var name = (nameAttr.value as StringLiteral).value;
            Iterable<ElementChild> children;

            if (!blocks.containsKey(name)) {
              children = child.children;
            } else {
              children = blocks[name].children;
            }

            expanded.addAll(children);
          }
        } else {
          throw new UnsupportedError(
              'Unsupported element type: ${element.runtimeType}');
        }
      } else {
        expanded.add(child);
      }
    }

    // Resolve all includes...
    expanded = await Future.wait(expanded.map((c) {
      if (c is! Element) return new Future.value(c);
      return _expandIncludes(c, currentDirectory, onError);
    }));

    return new RegularElement(
        element.lt,
        element.tagName,
        element.attributes,
        element.gt,
        expanded,
        element.lt2,
        element.slash,
        element.tagName2,
        element.gt2);
  } else {
    throw new UnsupportedError(
        'Unsupported element type: ${element.runtimeType}');
  }
}

/// Expands all `include[src]` tags within the template, and fills in the content of referenced files.
Future<Document> resolveIncludes(Document document, Directory currentDirectory,
    void onError(JaelError error)) async {
  return new Document(document.doctype,
      await _expandIncludes(document.root, currentDirectory, onError));
}

Future<Element> _expandIncludes(Element element, Directory currentDirectory,
    void onError(JaelError error)) async {
  if (element.tagName.name != 'include') {
    if (element is SelfClosingElement)
      return element;
    else if (element is RegularElement) {
      List<ElementChild> expanded = [];

      for (var child in element.children) {
        if (child is Element) {
          expanded.add(await _expandIncludes(child, currentDirectory, onError));
        } else {
          expanded.add(child);
        }
      }

      return new RegularElement(
          element.lt,
          element.tagName,
          element.attributes,
          element.gt,
          expanded,
          element.lt2,
          element.slash,
          element.tagName2,
          element.gt2);
    } else {
      throw new UnsupportedError(
          'Unsupported element type: ${element.runtimeType}');
    }
  }

  var attr = element.attributes
      .firstWhere((a) => a.name.name == 'src', orElse: () => null);
  if (attr == null) {
    onError(new JaelError(JaelErrorSeverity.warning,
        'Missing "src" attribute in "include" tag.', element.tagName.span));
    return null;
  } else if (attr.value is! StringLiteral) {
    onError(new JaelError(
        JaelErrorSeverity.warning,
        'The "src" attribute in an "include" tag must be a string literal.',
        element.tagName.span));
    return null;
  } else {
    var src = (attr.value as StringLiteral).value;
    var file =
        currentDirectory.fileSystem.file(currentDirectory.uri.resolve(src));
    var contents = await file.readAsString();
    var doc = parseDocument(contents, sourceUrl: file.uri, onError: onError);
    var processed = await resolve(
        doc, currentDirectory.fileSystem.directory(file.dirname),
        onError: onError);
    return processed.root;
  }
}
