import 'dart:async';
import 'dart:collection';
import 'package:file/file.dart';
import 'package:jael/jael.dart';

/// Modifies a Jael document.
typedef FutureOr<Document> Patcher(Document document,
    Directory currentDirectory, void onError(JaelError error));

/// Expands all `block[name]` tags within the template, replacing them with the correct content.
///
/// To apply additional patches to resolved documents, provide a set of [patch]
/// functions.
Future<Document> resolve(Document document, Directory currentDirectory,
    {void onError(JaelError error), Iterable<Patcher> patch}) async {
  onError ?? (e) => throw e;

  // Resolve all includes...
  var includesResolved =
      await resolveIncludes(document, currentDirectory, onError);
  var patched =
      await applyInheritance(includesResolved, currentDirectory, onError);

  if (patch?.isNotEmpty != true) return patched;

  for (var p in patch) {
    patched = await p(patched, currentDirectory, onError);
  }

  return patched;
}

/// Folds any `extend` declarations.
Future<Document> applyInheritance(Document document, Directory currentDirectory,
    void onError(JaelError error)) async {
  if (document.root.tagName.name != 'extend') return document;

  var element = document.root;
  var attr =
      element.attributes.firstWhere((a) => a.name == 'src', orElse: () => null);
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
    // First, we need to identify the root template.
    var chain = new Queue<Document>();

    while (document != null) {
      chain.addFirst(document);
      var parent = getParent(document, onError);
      if (parent == null) break;
      var file = currentDirectory.fileSystem
          .file(currentDirectory.uri.resolve(parent));
      var contents = await file.readAsString();
      document = parseDocument(contents, sourceUrl: file.uri, onError: onError);
      if (document != null)
        document = await resolveIncludes(document, file.parent, onError);
    }

    // Then, for each referenced template, in order, transform the last template
    // by filling in blocks.
    document = chain.removeFirst();

    while (chain.isNotEmpty) {
      var child = chain.removeFirst();
      var blocks = extractBlockDeclarations(child.root, onError);
      var blocksExpanded =
          await expandBlocks(document.root, blocks, currentDirectory, onError);
      document =
          new Document(child.doctype ?? document.doctype, blocksExpanded);
    }

    // Fill in any remaining blocks
    var blocksExpanded =
        await expandBlocks(document.root, {}, currentDirectory, onError);
    return new Document(document.doctype, blocksExpanded);
  }
}

/// Extracts any `block` declarations.
Map<String, Element> extractBlockDeclarations(
    Element element, void onError(JaelError error)) {
  Map<String, Element> blocks = {};
  var blockElements =
      element.children.where((e) => e is Element && e.tagName.name == 'block');

  for (Element blockElement in blockElements) {
    var nameAttr = blockElement.attributes
        .firstWhere((a) => a.name == 'name', orElse: () => null);
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

  return blocks;
}

/// Finds the name of the parent template.
String getParent(Document document, void onError(JaelError error)) {
  var element = document.root;
  if (element.tagName.name != 'extend') return null;

  var attr =
      element.attributes.firstWhere((a) => a.name == 'src', orElse: () => null);
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
    return (attr.value as StringLiteral).value;
  }
}

/// Replaces any `block` tags within the element.
Future<Element> expandBlocks(Element element, Map<String, Element> blocks,
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
            var nameAttr = child.attributes
                .firstWhere((a) => a.name == 'name', orElse: () => null);
            if (nameAttr == null) {
              onError(new JaelError(JaelErrorSeverity.warning,
                  'Missing "name" attribute in "block" tag.', child.span));
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
      return expandBlocks(c, blocks, currentDirectory, onError);
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

  var attr =
      element.attributes.firstWhere((a) => a.name == 'src', orElse: () => null);
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
