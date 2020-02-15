import 'dart:async';
import 'dart:collection';
import 'package:file/file.dart';
import 'package:jael/jael.dart';
import 'package:symbol_table/symbol_table.dart';

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

  var patched = await applyInheritance(
      includesResolved, currentDirectory, onError, patch);

  if (patch?.isNotEmpty != true) return patched;

  for (var p in patch) {
    patched = await p(patched, currentDirectory, onError);
  }

  return patched;
}

/// Folds any `extend` declarations.
Future<Document> applyInheritance(Document document, Directory currentDirectory,
    void onError(JaelError error), Iterable<Patcher> patch) async {
  if (document.root.tagName.name != 'extend') {
    // This is not an inherited template, so just fill in the existing blocks.
    var root =
        replaceChildrenOfElement(document.root, {}, onError, true, false);
    return new Document(document.doctype, root);
  }

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
    // In theory, there exists:
    // * A single root template with a number of blocks
    // * Some amount of <extend src="..."> templates.

    // To produce an accurate representation, we need to:
    // 1. Find the root template, and store a copy in a variable.
    // 2: For each <extend> template:
    //  a. Enumerate the block overrides it defines
    //  b. Replace matching blocks in the current document
    //  c. If there is no block, and this is the LAST <extend>, fill in the default block content.
    var hierarchy = await resolveHierarchy(document, currentDirectory, onError);
    var out = hierarchy?.root;

    if (out is! RegularElement) {
      return hierarchy.rootDocument;
    }

    Element setOut(Element out, Map<String, RegularElement> definedOverrides,
        bool anyTemplatesRemain) {
      var children = <ElementChild>[];

      // Replace matching blocks, etc.
      for (var c in out.children) {
        if (c is Element) {
          children.addAll(replaceBlocks(
              c, definedOverrides, onError, false, anyTemplatesRemain));
        } else {
          children.add(c);
        }
      }

      var root = hierarchy.root as RegularElement;
      return new RegularElement(root.lt, root.tagName, root.attributes, root.gt,
          children, root.lt2, root.slash, root.tagName2, root.gt2);
    }

    // Loop through all extends, filling in blocks.
    while (hierarchy.extendsTemplates.isNotEmpty) {
      var tmpl = hierarchy.extendsTemplates.removeFirst();
      var definedOverrides = findBlockOverrides(tmpl, onError);
      if (definedOverrides == null) break;
      out =
          setOut(out, definedOverrides, hierarchy.extendsTemplates.isNotEmpty);
    }

    // Lastly, just default-fill any remaining blocks.
    var definedOverrides = findBlockOverrides(out, onError);
    if (definedOverrides != null) out = setOut(out, definedOverrides, false);

    // Return our processed document.
    return new Document(document.doctype, out);
  }
}

Map<String, RegularElement> findBlockOverrides(
    Element tmpl, void onError(JaelError e)) {
  var out = <String, RegularElement>{};

  for (var child in tmpl.children) {
    if (child is RegularElement && child.tagName?.name == 'block') {
      var name = child.attributes
          .firstWhere((a) => a.name == 'name', orElse: () => null)
          ?.value
          ?.compute(new SymbolTable()) as String;
      if (name?.trim()?.isNotEmpty == true) {
        out[name] = child;
      }
    }
  }

  return out;
}

/// Resolves the document hierarchy at a given node in the tree.
Future<DocumentHierarchy> resolveHierarchy(Document document,
    Directory currentDirectory, void onError(JaelError e)) async {
  var extendsTemplates = new Queue<Element>();
  String parent;

  while (document != null && (parent = getParent(document, onError)) != null) {
    try {
      extendsTemplates.addFirst(document.root);
      var file = currentDirectory.childFile(parent);
      var parsed = parseDocument(await file.readAsString(),
          sourceUrl: file.uri, onError: onError);
      document = await resolveIncludes(parsed, currentDirectory, onError);
    } on FileSystemException catch (e) {
      onError(new JaelError(
          JaelErrorSeverity.error, e.message, document.root.span));
      return null;
    }
  }

  if (document == null) return null;
  return new DocumentHierarchy(document, extendsTemplates);
}

class DocumentHierarchy {
  final Document rootDocument;
  final Queue<Element> extendsTemplates; // FIFO

  DocumentHierarchy(this.rootDocument, this.extendsTemplates);

  Element get root => rootDocument.root;
}

Iterable<ElementChild> replaceBlocks(
    Element element,
    Map<String, RegularElement> definedOverrides,
    void onError(JaelError e),
    bool replaceWithDefault,
    bool anyTemplatesRemain) {
  if (element.tagName.name == 'block') {
    var nameAttr = element.attributes
        .firstWhere((a) => a.name == 'name', orElse: () => null);
    var name = nameAttr?.value?.compute(new SymbolTable());

    if (name?.trim()?.isNotEmpty != true) {
      onError(new JaelError(
          JaelErrorSeverity.warning,
          'This <block> has no `name` attribute, and will be outputted as-is.',
          element.span));
      return [element];
    } else if (!definedOverrides.containsKey(name)) {
      if (element is RegularElement) {
        if (anyTemplatesRemain || !replaceWithDefault) {
          // If there are still templates remaining, this current block may eventually
          // be resolved. Keep it alive.

          // We can't get rid of the block itself, but it may have blocks as children...
          var inner = allChildrenOfRegularElement(element, definedOverrides,
              onError, replaceWithDefault, anyTemplatesRemain);

          return [
            new RegularElement(
                element.lt,
                element.tagName,
                element.attributes,
                element.gt,
                inner,
                element.lt2,
                element.slash,
                element.tagName2,
                element.gt2)
          ];
        } else {
          // Otherwise, just return the default contents.
          return element.children;
        }
      } else {
        return [element];
      }
    } else {
      return allChildrenOfRegularElement(definedOverrides[name],
          definedOverrides, onError, replaceWithDefault, anyTemplatesRemain);
    }
  } else if (element is SelfClosingElement) {
    return [element];
  } else {
    return [
      replaceChildrenOfRegularElement(element as RegularElement,
          definedOverrides, onError, replaceWithDefault, anyTemplatesRemain)
    ];
  }
}

Element replaceChildrenOfElement(
    Element el,
    Map<String, RegularElement> definedOverrides,
    void onError(JaelError e),
    bool replaceWithDefault,
    bool anyTemplatesRemain) {
  if (el is RegularElement) {
    return replaceChildrenOfRegularElement(
        el, definedOverrides, onError, replaceWithDefault, anyTemplatesRemain);
  } else {
    return el;
  }
}

RegularElement replaceChildrenOfRegularElement(
    RegularElement el,
    Map<String, RegularElement> definedOverrides,
    void onError(JaelError e),
    bool replaceWithDefault,
    bool anyTemplatesRemain) {
  var children = allChildrenOfRegularElement(
      el, definedOverrides, onError, replaceWithDefault, anyTemplatesRemain);
  return new RegularElement(el.lt, el.tagName, el.attributes, el.gt, children,
      el.lt2, el.slash, el.tagName2, el.gt2);
}

List<ElementChild> allChildrenOfRegularElement(
    RegularElement el,
    Map<String, RegularElement> definedOverrides,
    void onError(JaelError e),
    bool replaceWithDefault,
    bool anyTemplatesRemain) {
  var children = <ElementChild>[];

  for (var c in el.children) {
    if (c is Element) {
      children.addAll(replaceBlocks(c, definedOverrides, onError,
          replaceWithDefault, anyTemplatesRemain));
    } else {
      children.add(c);
    }
  }

  return children;
}

/// Finds the name of the parent template.
String getParent(Document document, void onError(JaelError error)) {
  var element = document.root;
  if (element?.tagName?.name != 'extend') return null;

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
