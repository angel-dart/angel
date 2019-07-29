import '../ast/ast.dart';
import 'parselet/parselet.dart';
import 'scanner.dart';

class Parser {
  final List<JaelError> errors = [];
  final Scanner scanner;
  final bool asDSX;

  Token _current;
  int _index = -1;

  Parser(this.scanner, {this.asDSX = false});

  Token get current => _current;

  int _nextPrecedence() {
    var tok = peek();
    if (tok == null) return 0;

    var parser = infixParselets[tok.type];
    return parser?.precedence ?? 0;
  }

  bool next(TokenType type) {
    if (_index >= scanner.tokens.length - 1) return false;
    var peek = scanner.tokens[_index + 1];

    if (peek.type != type) return false;

    _current = peek;
    _index++;
    return true;
  }

  Token peek() {
    if (_index >= scanner.tokens.length - 1) return null;
    return scanner.tokens[_index + 1];
  }

  Token maybe(TokenType type) => next(type) ? _current : null;

  void skipExtraneous(TokenType type) {
    while (next(type)) {
      // Skip...
    }
  }

  Document parseDocument() {
    var doctype = parseDoctype();

    if (doctype == null) {
      var root = parseElement();
      if (root == null) return null;
      return Document(null, root);
    }

    var root = parseElement();

    if (root == null) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing root element after !DOCTYPE declaration.', doctype.span));
      return null;
    }

    return Document(doctype, root);
  }

  StringLiteral implicitString() {
    if (next(TokenType.string)) {
      return prefixParselets[TokenType.string].parse(this, _current)
          as StringLiteral;
    }
    /*else if (next(TokenType.text)) {

    }*/

    return null;
  }

  Doctype parseDoctype() {
    if (!next(TokenType.lt)) return null;
    var lt = _current;

    if (!next(TokenType.doctype)) {
      _index--;
      return null;
    }
    var doctype = _current, html = parseIdentifier();
    if (html?.span?.text?.toLowerCase() != 'html') {
      errors.add(JaelError(
          JaelErrorSeverity.error,
          'Expected "html" in doctype declaration.',
          html?.span ?? doctype.span));
      return null;
    }

    var public = parseIdentifier();
    if (public == null) {
      if (!next(TokenType.gt)) {
        errors.add(JaelError(JaelErrorSeverity.error,
            'Expected ">" in doctype declaration.', html.span));
        return null;
      }

      return Doctype(lt, doctype, html, null, null, null, _current);
    }

    if (public?.span?.text?.toLowerCase() != 'public') {
      errors.add(JaelError(
          JaelErrorSeverity.error,
          'Expected "public" in doctype declaration.',
          public?.span ?? html.span));
      return null;
    }

    var stringParser = prefixParselets[TokenType.string];

    if (!next(TokenType.string)) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Expected string in doctype declaration.', public.span));
      return null;
    }

    var name = stringParser.parse(this, _current) as StringLiteral;

    if (!next(TokenType.string)) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Expected string in doctype declaration.', name.span));
      return null;
    }

    var url = stringParser.parse(this, _current) as StringLiteral;

    if (!next(TokenType.gt)) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Expected ">" in doctype declaration.', url.span));
      return null;
    }

    return Doctype(lt, doctype, html, public, name, url, _current);
  }

  ElementChild parseElementChild() =>
      parseHtmlComment() ??
      parseInterpolation() ??
      parseText() ??
      parseElement();

  HtmlComment parseHtmlComment() =>
      next(TokenType.htmlComment) ? HtmlComment(_current) : null;

  Text parseText() => next(TokenType.text) ? Text(_current) : null;

  Interpolation parseInterpolation() {
    if (!next(asDSX ? TokenType.lCurly : TokenType.lDoubleCurly)) return null;
    var doubleCurlyL = _current;

    var expression = parseExpression(0);

    if (expression == null) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing expression in interpolation.', doubleCurlyL.span));
      return null;
    }

    if (!next(asDSX ? TokenType.rCurly : TokenType.rDoubleCurly)) {
      var expected = asDSX ? '}' : '}}';
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing closing "$expected" in interpolation.', expression.span));
      return null;
    }

    return Interpolation(doubleCurlyL, expression, _current);
  }

  Element parseElement() {
    if (!next(TokenType.lt)) return null;
    var lt = _current;

    if (next(TokenType.slash)) {
      // We entered a closing tag, don't keep reading...
      _index -= 2;
      return null;
    }

    var tagName = parseIdentifier();

    if (tagName == null) {
      errors.add(
          JaelError(JaelErrorSeverity.error, 'Missing tag name.', lt.span));
      return null;
    }

    List<Attribute> attributes = [];
    var attribute = parseAttribute();

    while (attribute != null) {
      attributes.add(attribute);
      attribute = parseAttribute();
    }

    if (next(TokenType.slash)) {
      // Try for self-closing...
      var slash = _current;

      if (!next(TokenType.gt)) {
        errors.add(JaelError(JaelErrorSeverity.error,
            'Missing ">" in self-closing "${tagName.name}" tag.', slash.span));
        return null;
      }

      return SelfClosingElement(lt, tagName, attributes, slash, _current);
    }

    if (!next(TokenType.gt)) {
      errors.add(JaelError(
          JaelErrorSeverity.error,
          'Missing ">" in "${tagName.name}" tag.',
          attributes.isEmpty ? tagName.span : attributes.last.span));
      return null;
    }

    var gt = _current;

    // Implicit self-closing
    if (Element.selfClosing.contains(tagName.name)) {
      return SelfClosingElement(lt, tagName, attributes, null, gt);
    }

    List<ElementChild> children = [];
    var child = parseElementChild();

    while (child != null) {
      // if (child is! HtmlComment) children.add(child);
      children.add(child);
      child = parseElementChild();
    }

    // Parse closing tag
    if (!next(TokenType.lt)) {
      errors.add(JaelError(
          JaelErrorSeverity.error,
          'Missing closing tag for "${tagName.name}" tag.',
          children.isEmpty ? tagName.span : children.last.span));
      return null;
    }

    var lt2 = _current;

    if (!next(TokenType.slash)) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing "/" in "${tagName.name}" closing tag.', lt2.span));
      return null;
    }

    var slash = _current, tagName2 = parseIdentifier();

    if (tagName2 == null) {
      errors.add(JaelError(
          JaelErrorSeverity.error,
          'Missing "${tagName.name}" in "${tagName.name}" closing tag.',
          slash.span));
      return null;
    }

    if (tagName2.name != tagName.name) {
      errors.add(JaelError(
          JaelErrorSeverity.error,
          'Mismatched closing tags. Expected "${tagName.span.text}"; got "${tagName2.name}" instead.',
          lt2.span));
      return null;
    }

    if (!next(TokenType.gt)) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing ">" in "${tagName.name}" closing tag.', tagName2.span));
      return null;
    }

    return RegularElement(
        lt, tagName, attributes, gt, children, lt2, slash, tagName2, _current);
  }

  Attribute parseAttribute() {
    Identifier id;
    StringLiteral string;

    if ((id = parseIdentifier()) != null) {
      // Nothing
    } else if (next(TokenType.string)) {
      string = StringLiteral(_current, StringLiteral.parseValue(_current));
    } else {
      return null;
    }

    Token equals, nequ;

    if (next(TokenType.equals)) {
      equals = _current;
    } else if (!asDSX && next(TokenType.nequ)) {
      nequ = _current;
    } else {
      return Attribute(id, string, null, null, null);
    }

    if (!asDSX) {
      var value = parseExpression(0);

      if (value == null) {
        errors.add(JaelError(JaelErrorSeverity.error,
            'Missing expression in attribute.', equals?.span ?? nequ.span));
        return null;
      }

      return Attribute(id, string, equals, nequ, value);
    } else {
      // Find either a string, or an interpolation.
      var value = implicitString();

      if (value != null) {
        return Attribute(id, string, equals, nequ, value);
      }

      var interpolation = parseInterpolation();

      if (interpolation != null) {
        return Attribute(id, string, equals, nequ, interpolation.expression);
      }

      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing expression in attribute.', equals?.span ?? nequ.span));
      return null;
    }
  }

  Expression parseExpression(int precedence) {
    // Only consume a token if it could potentially be a prefix parselet

    for (var type in prefixParselets.keys) {
      if (next(type)) {
        var left = prefixParselets[type].parse(this, _current);

        while (precedence < _nextPrecedence()) {
          _current = scanner.tokens[++_index];

          if (_current.type == TokenType.slash &&
              peek()?.type == TokenType.gt) {
            // Handle `/>`
            //
            // Don't register this as an infix expression.
            // Instead, backtrack, and return the current expression.
            _index--;
            return left;
          }

          var infix = infixParselets[_current.type];
          var newLeft = infix.parse(this, left, _current);

          if (newLeft == null) {
            if (_current.type == TokenType.gt) _index--;
            return left;
          }
          left = newLeft;
        }

        return left;
      }
    }

    // Nothing was parsed; return null.
    return null;
  }

  Identifier parseIdentifier() =>
      next(TokenType.id) ? Identifier(_current) : null;

  KeyValuePair parseKeyValuePair() {
    var key = parseExpression(0);
    if (key == null) return null;

    if (!next(TokenType.colon)) return KeyValuePair(key, null, null);

    var colon = _current, value = parseExpression(0);

    if (value == null) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing expression in key-value pair.', colon.span));
      return null;
    }

    return KeyValuePair(key, colon, value);
  }

  NamedArgument parseNamedArgument() {
    var name = parseIdentifier();
    if (name == null) return null;

    if (!next(TokenType.colon)) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing ":" in named argument.', name.span));
      return null;
    }

    var colon = _current, value = parseExpression(0);

    if (value == null) {
      errors.add(JaelError(JaelErrorSeverity.error,
          'Missing expression in named argument.', colon.span));
      return null;
    }

    return NamedArgument(name, colon, value);
  }
}
