library graphql_parser.language.parser;

import 'ast/ast.dart';
import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';

class Parser {
  Token _current;
  final List<SyntaxError> _errors = [];
  int _index = -1;

  final List<Token> tokens;

  Parser(this.tokens);

  Token get current => _current;

  List<SyntaxError> get errors => new List<SyntaxError>.unmodifiable(_errors);

  bool next(TokenType type) {
    if (peek()?.type == type) {
      _current = tokens[++_index];
      return true;
    }

    return false;
  }

  Token peek() {
    if (_index < tokens.length - 1) {
      return tokens[_index + 1];
    }

    return null;
  }

  DocumentContext parseDocument() {}

  FragmentDefinitionContext parseFragmentDefinition() {}

  FragmentSpreadContext parseFragmentSpread() {}

  InlineFragmentContext parseInlineFragment() {}

  SelectionSetContext parseSelectionSet() {}

  SelectionContext parseSelection() {}

  FieldContext parseField() {}

  FieldNameContext parseFieldName() {}

  AliasContext parseAlias() {}

  VariableDefinitionsContext parseVariableDefinitions() {}

  VariableDefinitionContext parseVariableDefinition() {}

  List<DirectiveContext> parseDirectives() {}

  DirectiveContext parseDirective() {
    if (next(TokenType.ARROBA)) {
      var ARROBA = current;
      if (next(TokenType.NAME)) {
        var NAME = current;

        if (next(TokenType.COLON)) {
          var COLON = current;
          var val = parseValueOrVariable();
          if (val != null)
            return new DirectiveContext(
                ARROBA, NAME, COLON, null, null, null, val);
          else
            throw new SyntaxError.fromSourceLocation(
                'Expected value or variable in directive after colon.',
                COLON.span.end);
        } else if (next(TokenType.LPAREN)) {
          var LPAREN = current;
          var arg = parseArgument();
          if (arg != null) {
            if (next(TokenType.RPAREN)) {
              return new DirectiveContext(
                  ARROBA, NAME, null, LPAREN, current, arg, null);
            } else
              throw new SyntaxError.fromSourceLocation(
                  'Expected \'(\'', arg.valueOrVariable.span.end);
          } else
            throw new SyntaxError.fromSourceLocation(
                'Expected argument in directive.', LPAREN.span.end);
        } else
          return new DirectiveContext(
              ARROBA, NAME, null, null, null, null, null);
      } else
        throw new SyntaxError.fromSourceLocation(
            'Expected name for directive.', ARROBA.span.end);
    } else
      return null;
  }

  ArgumentContext parseArgument() {
    if (next(TokenType.NAME)) {
      var NAME = current;
      if (next(TokenType.COLON)) {
        var COLON = current;
        var val = parseValueOrVariable();
        if (val != null)
          return new ArgumentContext(NAME, COLON, val);
        else
          throw new SyntaxError.fromSourceLocation(
              'Expected value or variable in argument.', COLON.span.end);
      } else
        throw new SyntaxError.fromSourceLocation(
            'Expected colon after name in argument.', NAME.span.end);
    } else
      return null;
  }

  ValueOrVariableContext parseValueOrVariable() {
    var value = parseValue();
    if (value != null)
      return new ValueOrVariableContext(value, null);
    else {
      var variable = parseVariable();
      if (variable != null)
        return new ValueOrVariableContext(null, variable);
      else
        return null;
    }
  }

  VariableContext parseVariable() {
    if (next(TokenType.DOLLAR)) {
      var DOLLAR = current;
      if (next(TokenType.NAME))
        return new VariableContext(DOLLAR, current);
      else
        throw new SyntaxError.fromSourceLocation(
            'Expected name for variable; found a lone "\$" instead.',
            DOLLAR.span.end);
    } else
      return null;
  }

  DefaultValueContext parseDefaultValue() {}

  TypeConditionContext parseTypeCondition() {}

  ValueContext parseValue() {
    return parseStringValue() ??
        parseNumberValue() ??
        parseBooleanValue() ??
        parseArrayValue();
  }

  StringValueContext parseStringValue() =>
      next(TokenType.STRING) ? new StringValueContext(current) : null;

  NumberValueContext parseNumberValue() =>
      next(TokenType.NUMBER) ? new NumberValueContext(current) : null;

  BooleanValueContext parseBooleanValue() =>
      next(TokenType.BOOLEAN) ? new BooleanValueContext(current) : null;

  ArrayValueContext parseArrayValue() {
    if (next(TokenType.LBRACKET)) {
      var LBRACKET = current;
      List<ValueContext> values = [];
      ValueContext value = parseValue();

      while (value != null) {
        values.add(value);
        if (next(TokenType.COMMA)) {
          value = parseValue();
        } else
          break;
      }

      if (next(TokenType.RBRACKET)) {
        return new ArrayValueContext(LBRACKET, current)..values.addAll(values);
      } else
        throw new SyntaxError.fromSourceLocation(
            'Unterminated array literal.', LBRACKET.span.end);
    } else
      return null;
  }
}
