import 'package:code_buffer/code_buffer.dart';
import 'package:dart2_constant/convert.dart';
import 'package:symbol_table/symbol_table.dart';
import 'ast/ast.dart';
import 'text/parser.dart';
import 'text/scanner.dart';

/// Parses a Jael document.
Document parseDocument(String text,
    {sourceUrl, void onError(JaelError error)}) {
  var scanner = scan(text, sourceUrl: sourceUrl);

  //scanner.tokens.forEach(print);

  if (scanner.errors.isNotEmpty && onError != null)
    scanner.errors.forEach(onError);
  else if (scanner.errors.isNotEmpty) throw scanner.errors.first;

  var parser = new Parser(scanner);
  var doc = parser.parseDocument();

  if (parser.errors.isNotEmpty && onError != null)
    parser.errors.forEach(onError);
  else if (parser.errors.isNotEmpty) throw parser.errors.first;

  return doc;
}

class Renderer {
  const Renderer();

  /// Render an error page.
  static void errorDocument(Iterable<JaelError> errors, CodeBuffer buf) {
    buf
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="en">')
      ..indent()
      ..writeln('<head>')
      ..indent()
      ..writeln(
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
      )
      ..writeln('<title>${errors.length} Error(s)</title>')
      ..outdent()
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<h1>${errors.length} Error(s)</h1>')
      ..writeln('<ul>')
      ..indent();

    for (var error in errors) {
      var type =
      error.severity == JaelErrorSeverity.warning ? 'warning' : 'error';
      buf
        ..writeln('<li>')
        ..indent()
        ..writeln(
            '<b>$type:</b> ${error.span.start.toolString}: ${error.message}')
        ..writeln('<br>')
        ..writeln(
          '<span style="color: red;">' +
              htmlEscape
                  .convert(error.span.highlight(color: false))
                  .replaceAll('\n', '<br>') +
              '</span>',
        )
        ..outdent()
        ..writeln('</li>');
    }

    buf
      ..outdent()
      ..writeln('</ul>')
      ..writeln('</body>')
      ..writeln('</html>');
  }

  /// Renders a [document] into the [buffer] as HTML.
  ///
  /// If [strictResolution] is `false` (default: `true`), then undefined identifiers will return `null`
  /// instead of throwing.
  void render(Document document, CodeBuffer buffer, SymbolTable scope, {bool strictResolution: true}) {
    scope.create('!strict!', value: strictResolution != false);

    if (document.doctype != null) buffer.writeln(document.doctype.span.text);
    renderElement(
        document.root, buffer, scope, document.doctype?.public == null);
  }

  void renderElement(
      Element element, CodeBuffer buffer, SymbolTable scope, bool html5) {
    var childScope = scope.createChild();

    if (element.attributes.any((a) => a.name == 'for-each')) {
      renderForeach(element, buffer, childScope, html5);
      return;
    } else if (element.attributes.any((a) => a.name == 'if')) {
      renderIf(element, buffer, childScope, html5);
      return;
    } else if (element.tagName.name == 'declare') {
      renderDeclare(element, buffer, childScope, html5);
      return;
    } else if (element.tagName.name == 'switch') {
      renderSwitch(element, buffer, childScope, html5);
      return;
    }

    buffer..write('<')..write(element.tagName.name);

    for (var attribute in element.attributes) {
      var value = attribute.value?.compute(childScope);

      if (value == false || value == null) continue;

      buffer.write(' ${attribute.name}');

      if (value == true)
        continue;
      else
        buffer.write('="');

      String msg;

      if (value is Iterable) {
        msg = value.join(' ');
      } else if (value is Map) {
        msg = value.keys.fold<StringBuffer>(new StringBuffer(), (buf, k) {
          var v = value[k];
          if (v == null) return buf;
          return buf..write('$k: $v;');
        }).toString();
      } else {
        msg = value.toString();
      }

      buffer.write(attribute.isRaw ? msg : htmlEscape.convert(msg));
      buffer.write('"');
    }

    if (element is SelfClosingElement) {
      if (html5)
        buffer.writeln('>');
      else
        buffer.writeln('/>');
    } else {
      buffer.writeln('>');
      buffer.indent();

      for (int i = 0; i < element.children.length; i++) {
        var child = element.children.elementAt(i);
        renderElementChild(
            child, buffer, childScope, html5, i, element.children.length);
      }

      buffer.writeln();
      buffer.outdent();
      buffer.writeln('</${element.tagName.name}>');
    }
  }

  void renderForeach(
      Element element, CodeBuffer buffer, SymbolTable scope, bool html5) {
    var attribute = element.attributes.singleWhere((a) => a.name == 'for-each');
    if (attribute.value == null) return;

    var asAttribute = element.attributes
        .firstWhere((a) => a.name == 'as', orElse: () => null);
    var alias = asAttribute?.value?.compute(scope) ?? 'item';
    var otherAttributes =
        element.attributes.where((a) => a.name != 'for-each' && a.name != 'as');
    Element strippedElement;

    if (element is SelfClosingElement)
      strippedElement = new SelfClosingElement(element.lt, element.tagName,
          otherAttributes, element.slash, element.gt);
    else if (element is RegularElement)
      strippedElement = new RegularElement(
          element.lt,
          element.tagName,
          otherAttributes,
          element.gt,
          element.children,
          element.lt2,
          element.slash,
          element.tagName2,
          element.gt2);

    for (var item in attribute.value.compute(scope)) {
      var childScope = scope.createChild(values: {alias: item});
      renderElement(strippedElement, buffer, childScope, html5);
    }
  }

  void renderIf(
      Element element, CodeBuffer buffer, SymbolTable scope, bool html5) {
    var attribute = element.attributes.singleWhere((a) => a.name == 'if');

    if (!attribute.value.compute(scope)) return;

    var otherAttributes = element.attributes.where((a) => a.name != 'if');
    Element strippedElement;

    if (element is SelfClosingElement)
      strippedElement = new SelfClosingElement(element.lt, element.tagName,
          otherAttributes, element.slash, element.gt);
    else if (element is RegularElement)
      strippedElement = new RegularElement(
          element.lt,
          element.tagName,
          otherAttributes,
          element.gt,
          element.children,
          element.lt2,
          element.slash,
          element.tagName2,
          element.gt2);

    renderElement(strippedElement, buffer, scope, html5);
  }

  void renderDeclare(
      Element element, CodeBuffer buffer, SymbolTable scope, bool html5) {
    for (var attribute in element.attributes) {
      scope.create(attribute.name,
          value: attribute.value?.compute(scope), constant: true);
    }

    for (int i = 0; i < element.children.length; i++) {
      var child = element.children.elementAt(i);
      renderElementChild(
          child, buffer, scope, html5, i, element.children.length);
    }
  }

  void renderSwitch(
      Element element, CodeBuffer buffer, SymbolTable scope, bool html5) {
    var value = element.attributes
        .firstWhere((a) => a.name == 'value', orElse: () => null)
        ?.value
        ?.compute(scope);

    var cases =
        element.children.where((c) => c is Element && c.tagName.name == 'case');

    for (Element child in cases) {
      var comparison = child.attributes
          .firstWhere((a) => a.name == 'value', orElse: () => null)
          ?.value
          ?.compute(scope);
      if (comparison == value) {
        for (int i = 0; i < child.children.length; i++) {
          var c = child.children.elementAt(i);
          renderElementChild(c, buffer, scope, html5, i, child.children.length);
        }

        return;
      }
    }

    Element defaultCase = element.children.firstWhere(
        (c) => c is Element && c.tagName.name == 'default',
        orElse: () => null);
    if (defaultCase != null) {
      for (int i = 0; i < defaultCase.children.length; i++) {
        var child = defaultCase.children.elementAt(i);
        renderElementChild(
            child, buffer, scope, html5, i, defaultCase.children.length);
      }
    }
  }

  void renderElementChild(ElementChild child, CodeBuffer buffer,
      SymbolTable scope, bool html5, int index, int total) {
    if (child is Text) {
      if (index == 0)
        buffer.write(child.span.text.trimLeft());
      else if (index == total - 1)
        buffer.write(child.span.text.trimRight());
      else
        buffer.write(child.span.text);
    } else if (child is Interpolation) {
      var value = child.expression.compute(scope);

      if (value != null) {
        if (child.isRaw)
          buffer.write(value);
        else
          buffer.write(htmlEscape.convert(value.toString()));
      }
    } else if (child is Element) {
      if (buffer?.lastLine?.text?.isNotEmpty == true) buffer.writeln();
      renderElement(child, buffer, scope, html5);
    }
  }
}
