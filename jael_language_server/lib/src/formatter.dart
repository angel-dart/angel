import 'package:jael/jael.dart';

class JaelFormatter {
  final num tabSize;
  final bool insertSpaces;
  var _buffer = new StringBuffer();
  int _level = 0;
  String _spaces;

  static String _spaceString(int tabSize) {
    var b = new StringBuffer();
    for (int i = 0; i < tabSize; i++) {
      b.write(' ');
    }
    return b.toString();
  }

  JaelFormatter(this.tabSize, this.insertSpaces) {
    _spaces = insertSpaces ? _spaceString(tabSize.toInt()) : '\t';
  }

  void _indent() {
    _level++;
  }

  void _outdent() {
    if (_level > 0) _level--;
  }

  void _applySpacing() {
    for (int i = 0; i < _level; i++) _buffer.write(_spaces);
  }

  String apply(Document document) {
    if (document?.doctype != null) {
      _buffer.write('<!doctype');

      if (document.doctype.html != null) _buffer.write(' html');
      if (document.doctype.public != null) _buffer.write(' public');

      if (document.doctype.url != null) {
        _buffer.write('${document.doctype.url}');
      }

      _buffer.writeln();
    }

    _formatChild(document?.root);

    return _buffer.toString();
  }

  void _formatChild(ElementChild child) {
    if (child == null) return;
    _applySpacing();
    if (child is Text)
      _buffer.write(child.text.span.text);
    else if (child is TextNode)
      _buffer.write(child.text.span.text);
    else if (child is Element) _formatElement(child);
  }

  void _formatElement(Element element) {
    _applySpacing();
    _buffer.write('<${element.tagName.name}');

    for (var attr in element.attributes) {
      _buffer.write(' ${attr.name}');

      if (attr.value != null) {
        if (attr.value is Identifier) {
          var id = attr.value as Identifier;
          if (id.name == 'true') {
            _buffer.write(id.name);
          } else if (id.name != 'false') {
            if (attr.nequ != null) _buffer.write('!=');
            if (attr.equals != null) _buffer.write('=');
            _buffer.write(id.name);
          }
        } else {
          if (attr.nequ != null) _buffer.write('!=');
          if (attr.equals != null) _buffer.write('=');
          _buffer.write(attr.value.span.text);
        }
      }
    }

    if (element is SelfClosingElement) {
      _buffer.writeln('/>');
    } else if (element is RegularElement) {
      if (element.children.length == 1 &&
          (element.children.first is Text ||
              element.children.first is TextNode)) {
        _buffer.write('>');
        _buffer.write(element.children.first.span.text);
      } else {
        _buffer.writeln('>');
        _indent();
        element.children.forEach(_formatChild);
        _outdent();
      }

      if (element.children.isNotEmpty &&
          (element.children.last is Text ||
              element.children.last is TextNode)) {
        _buffer.writeln();
      }

      _applySpacing();
      _buffer.writeln('</${element.tagName.name}>');
    } else {
      throw new ArgumentError();
    }
  }
}
