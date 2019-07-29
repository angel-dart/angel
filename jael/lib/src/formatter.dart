import 'ast/ast.dart';

/// Jael formatter
class JaelFormatter {
  final num tabSize;
  final bool insertSpaces;
  final int maxLineLength;
  var _buffer = StringBuffer();
  int _level = 0;
  String _spaces;

  static String _spaceString(int tabSize) {
    var b = StringBuffer();
    for (int i = 0; i < tabSize; i++) {
      b.write(' ');
    }
    return b.toString();
  }

  JaelFormatter(this.tabSize, this.insertSpaces, this.maxLineLength) {
    _spaces = insertSpaces ? _spaceString(tabSize.toInt()) : '\t';
  }

  void _indent() {
    _level++;
  }

  void _outdent() {
    if (_level > 0) _level--;
  }

  void _applySpacing() {
    for (int i = 0; i < _level; i++) {
      _buffer.write(_spaces);
    }
  }

  int get _spaceLength {
    var out = 0;
    for (int i = 0; i < _level; i++) {
      out += _spaces.length;
    }
    return out;
  }

  String apply(Document document) {
    if (document?.doctype != null) {
      _buffer.write('<!doctype');

      if (document.doctype.html != null) _buffer.write(' html');
      if (document.doctype.public != null) _buffer.write(' public');

      if (document.doctype.url != null) {
        _buffer.write('${document.doctype.url}');
      }

      _buffer.writeln('>');
    }

    _formatChild(document?.root, 0);

    return _buffer.toString().trim();
  }

  int _formatChild(ElementChild child, int lineLength,
      {bool isFirst = false, bool isLast = false}) {
    if (child == null) {
      return lineLength;
    } else if (child is Element) return _formatElement(child, lineLength);
    String s;
    if (child is Interpolation) {
      var b = StringBuffer('{{');
      if (child.isRaw) b.write('-');
      b.write(' ');
      b.write(child.expression.span.text.trim());
      b.write(' }}');
      s = b.toString();
    } else {
      s = child.span.text;
    }
    if (isFirst) {
      s = s.trimLeft();
    }
    if (isLast) {
      s = s.trimRight();
    }

    var ll = lineLength + s.length;
    if (ll <= maxLineLength) {
      _buffer.write(s);
      return ll;
    } else {
      _buffer.writeln(s);
      return _spaceLength;
    }
  }

  int _formatElement(Element element, int lineLength) {
    // print([
    //   element.tagName.name,
    //   element.children.map((c) => c.runtimeType),
    // ]);
    var header = '<${element.tagName.name}';
    var attrParts = element.attributes.isEmpty
        ? <String>[]
        : element.attributes.map(_formatAttribute);
    var attrLen = attrParts.isEmpty
        ? 0
        : attrParts.map((s) => s.length).reduce((a, b) => a + b);
    _applySpacing();
    _buffer.write(header);

    // If the line will be less than maxLineLength characters, write all attrs.
    var ll = lineLength +
        (element is SelfClosingElement ? 2 : 1) +
        header.length +
        attrLen;
    if (ll <= maxLineLength) {
      attrParts.forEach(_buffer.write);
    } else {
      // Otherwise, them out with tabs.
      _buffer.writeln();
      _indent();
      var i = 0;
      for (var p in attrParts) {
        if (i++ > 0) {
          _buffer.writeln();
        }
        _applySpacing();
        _buffer.write(p);
      }
      _outdent();
    }

    if (element is SelfClosingElement) {
      _buffer.writeln('/>');
      return _spaceLength;
    } else {
      _buffer.write('>');
      if (element.children.isNotEmpty) {
        _buffer.writeln();
      }
    }

    _indent();
    var lll = _spaceLength;
    var i = 1;
    ElementChild last;
    for (var c in element.children) {
      if (lll == _spaceLength && c is! Element) {
        _applySpacing();
      }
      lll = _formatChild(c, lineLength + lll,
          isFirst: i == 1 || last is Element,
          isLast: i == element.children.length);
      if (i++ == element.children.length && c is! Element) {
        _buffer.writeln();
      }
      last = c;
    }
    _outdent();

    if (element.children.isNotEmpty) {
      // _buffer.writeln();
      _applySpacing();
    }
    _buffer.writeln('</${element.tagName.name}>');

    return lineLength;
  }

  String _formatAttribute(Attribute attr) {
    var b = StringBuffer();
    b.write(' ${attr.name}');

    if (attr.value != null) {
      if (attr.value is Identifier) {
        var id = attr.value as Identifier;
        if (id.name == 'true') {
          b.write(id.name);
        } else if (id.name != 'false') {
          if (attr.nequ != null) b.write('!=');
          if (attr.equals != null) b.write('=');
          b.write(id.name);
        }
      } else {
        if (attr.nequ != null) b.write('!=');
        if (attr.equals != null) b.write('=');
        b.write(attr.value.span.text);
      }
    }
    return b.toString();
  }
}
