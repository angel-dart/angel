library graphql_parser.language.parser;

import 'ast/ast.dart';
import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';

class Parser {
  Token _current;
  int _index = -1;

  final List<Token> tokens;

  Parser(this.tokens);

  Token get current => _current;

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

  Token maybe(TokenType type) => next(type) ? current : null;

  DocumentContext parseDocument() {
    List<DefinitionContext> defs = [];
    DefinitionContext def = parseDefinition();

    while (def != null) {
      defs.add(def);
      def = parseDefinition();
    }

    return new DocumentContext()..definitions.addAll(defs);
  }

  DefinitionContext parseDefinition() =>
      parseOperationDefinition() ?? parseFragmentDefinition();

  OperationDefinitionContext parseOperationDefinition() {
    var selectionSet = parseSelectionSet();
    if (selectionSet != null)
      return new OperationDefinitionContext(null, null, null, selectionSet);
    else {
      if (next(TokenType.MUTATION) || next(TokenType.QUERY)) {
        var TYPE = current;
        Token NAME = next(TokenType.NAME) ? current : null;
        var variables = parseVariableDefinitions();
        var dirs = parseDirectives();
        var selectionSet = parseSelectionSet();
        if (selectionSet != null)
          return new OperationDefinitionContext(
              TYPE, NAME, variables, selectionSet)
            ..directives.addAll(dirs);
        else
          throw new SyntaxError(
              'Expected selection set in fragment definition.', NAME.span);
      } else
        return null;
    }
  }

  FragmentDefinitionContext parseFragmentDefinition() {
    if (next(TokenType.FRAGMENT)) {
      var FRAGMENT = current;
      if (next(TokenType.NAME)) {
        var NAME = current;
        if (next(TokenType.ON)) {
          var ON = current;
          var typeCondition = parseTypeCondition();
          if (typeCondition != null) {
            var dirs = parseDirectives();
            var selectionSet = parseSelectionSet();
            if (selectionSet != null)
              return new FragmentDefinitionContext(
                  FRAGMENT, NAME, ON, typeCondition, selectionSet)
                ..directives.addAll(dirs);
            else
              throw new SyntaxError(
                  'Expected selection set in fragment definition.',
                  typeCondition.span);
          } else
            throw new SyntaxError(
                'Expected type condition after "on" in fragment definition.',
                ON.span);
        } else
          throw new SyntaxError(
              'Expected "on" after name "${NAME.text}" in fragment definition.',
              NAME.span);
      } else
        throw new SyntaxError(
            'Expected name after "fragment" in fragment definition.',
            FRAGMENT.span);
    } else
      return null;
  }

  FragmentSpreadContext parseFragmentSpread() {
    if (next(TokenType.ELLIPSIS)) {
      var ELLIPSIS = current;
      if (next(TokenType.NAME)) {
        var NAME = current;
        return new FragmentSpreadContext(ELLIPSIS, NAME)
          ..directives.addAll(parseDirectives());
      } else {
        _index--;
        return null;
      }
    } else
      return null;
  }

  InlineFragmentContext parseInlineFragment() {
    if (next(TokenType.ELLIPSIS)) {
      var ELLIPSIS = current;
      if (next(TokenType.ON)) {
        var ON = current;
        var typeCondition = parseTypeCondition();
        if (typeCondition != null) {
          var directives = parseDirectives();
          var selectionSet = parseSelectionSet();
          if (selectionSet != null) {
            return new InlineFragmentContext(
                ELLIPSIS, ON, typeCondition, selectionSet)
              ..directives.addAll(directives);
          } else
            throw new SyntaxError('Expected selection set in inline fragment.',
                directives.isEmpty ? typeCondition.span : directives.last.span);
        } else
          throw new SyntaxError(
              'Expected type condition after "on" in inline fragment.',
              ON.span);
      } else
        throw new SyntaxError(
            'Expected "on" after "..." in inline fragment.', ELLIPSIS.span);
    } else
      return null;
  }

  SelectionSetContext parseSelectionSet() {
    if (next(TokenType.LBRACE)) {
      var LBRACE = current;
      List<SelectionContext> selections = [];
      SelectionContext selection = parseSelection();

      while (selection != null) {
        selections.add(selection);
        next(TokenType.COMMA);
        selection = parseSelection();
      }

      if (next(TokenType.RBRACE))
        return new SelectionSetContext(LBRACE, current)
          ..selections.addAll(selections);
      else
        throw new SyntaxError('Expected "}" after selection set.',
            selections.isEmpty ? LBRACE.span : selections.last.span);
    } else
      return null;
  }

  SelectionContext parseSelection() {
    var field = parseField();
    if (field != null) return new SelectionContext(field);
    var fragmentSpread = parseFragmentSpread();
    if (fragmentSpread != null)
      return new SelectionContext(null, fragmentSpread);
    var inlineFragment = parseInlineFragment();
    if (inlineFragment != null)
      return new SelectionContext(null, null, inlineFragment);
    else
      return null;
  }

  FieldContext parseField() {
    var fieldName = parseFieldName();
    if (fieldName != null) {
      var args = parseArguments();
      var directives = parseDirectives();
      var selectionSet = parseSelectionSet();
      return new FieldContext(fieldName, selectionSet)
        ..arguments.addAll(args)
        ..directives.addAll(directives);
    } else
      return null;
  }

  FieldNameContext parseFieldName() {
    if (next(TokenType.NAME)) {
      var NAME1 = current;
      if (next(TokenType.COLON)) {
        var COLON = current;
        if (next(TokenType.NAME))
          return new FieldNameContext(
              null, new AliasContext(NAME1, COLON, current));
        else
          throw new SyntaxError(
              'Expected name after colon in alias.', COLON.span);
      } else
        return new FieldNameContext(NAME1);
    } else
      return null;
  }

  VariableDefinitionsContext parseVariableDefinitions() {
    if (next(TokenType.LPAREN)) {
      var LPAREN = current;
      List<VariableDefinitionContext> defs = [];
      VariableDefinitionContext def = parseVariableDefinition();

      while (def != null) {
        defs.add(def);
        maybe(TokenType.COMMA);
        def = parseVariableDefinition();
      }

      if (next(TokenType.RPAREN))
        return new VariableDefinitionsContext(LPAREN, current)
          ..variableDefinitions.addAll(defs);
      else
        throw new SyntaxError(
            'Expected ")" after variable definitions.', LPAREN.span);
    } else
      return null;
  }

  VariableDefinitionContext parseVariableDefinition() {
    var variable = parseVariable();
    if (variable != null) {
      if (next(TokenType.COLON)) {
        var COLON = current;
        var type = parseType();
        if (type != null) {
          var defaultValue = parseDefaultValue();
          return new VariableDefinitionContext(
              variable, COLON, type, defaultValue);
        } else
          throw new SyntaxError(
              'Expected type in variable definition.', COLON.span);
      } else
        throw new SyntaxError(
            'Expected ":" in variable definition.', variable.span);
    } else
      return null;
  }

  TypeContext parseType() {
    var name = parseTypeName();
    if (name != null) {
      return new TypeContext(name, null, maybe(TokenType.EXCLAMATION));
    } else {
      var listType = parseListType();
      if (listType != null) {
        return new TypeContext(null, listType, maybe(TokenType.EXCLAMATION));
      } else
        return null;
    }
  }

  ListTypeContext parseListType() {
    if (next(TokenType.LBRACKET)) {
      var LBRACKET = current;
      var type = parseType();
      if (type != null) {
        if (next(TokenType.RBRACKET)) {
          return new ListTypeContext(LBRACKET, type, current);
        } else
          throw new SyntaxError('Expected "]" in list type.', type.span);
      } else
        throw new SyntaxError('Expected type after "[".', LBRACKET.span);
    } else
      return null;
  }

  List<DirectiveContext> parseDirectives() {
    List<DirectiveContext> out = [];
    DirectiveContext d = parseDirective();
    while (d != null) {
      out.add(d);
      d = parseDirective();
    }

    return out;
  }

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
            throw new SyntaxError(
                'Expected value or variable in directive after colon.',
                COLON.span);
        } else if (next(TokenType.LPAREN)) {
          var LPAREN = current;
          var arg = parseArgument();
          if (arg != null) {
            if (next(TokenType.RPAREN)) {
              return new DirectiveContext(
                  ARROBA, NAME, null, LPAREN, current, arg, null);
            } else
              throw new SyntaxError('Expected \')\'', arg.valueOrVariable.span);
          } else
            throw new SyntaxError(
                'Expected argument in directive.', LPAREN.span);
        } else
          return new DirectiveContext(
              ARROBA, NAME, null, null, null, null, null);
      } else
        throw new SyntaxError('Expected name for directive.', ARROBA.span);
    } else
      return null;
  }

  List<ArgumentContext> parseArguments() {
    if (next(TokenType.LPAREN)) {
      var LPAREN = current;
      List<ArgumentContext> out = [];
      ArgumentContext arg = parseArgument();

      while (arg != null) {
        out.add(arg);
        if (next(TokenType.COMMA))
          arg = parseArgument();
        else
          break;
      }

      if (next(TokenType.RPAREN))
        return out;
      else
        throw new SyntaxError('Expected ")" in argument list.', LPAREN.span);
    } else
      return [];
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
          throw new SyntaxError(
              'Expected value or variable in argument.', COLON.span);
      } else
        throw new SyntaxError(
            'Expected colon after name in argument.', NAME.span);
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
        throw new SyntaxError(
            'Expected name for variable; found a lone "\$" instead.',
            DOLLAR.span);
    } else
      return null;
  }

  DefaultValueContext parseDefaultValue() {
    if (next(TokenType.EQUALS)) {
      var EQUALS = current;
      var value = parseValue();
      if (value != null) {
        return new DefaultValueContext(EQUALS, value);
      } else
        throw new SyntaxError('Expected value after "=" sign.', EQUALS.span);
    } else
      return null;
  }

  TypeConditionContext parseTypeCondition() {
    var name = parseTypeName();
    if (name != null)
      return new TypeConditionContext(name);
    else
      return null;
  }

  TypeNameContext parseTypeName() {
    if (next(TokenType.NAME)) {
      return new TypeNameContext(current);
    } else
      return null;
  }

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
        throw new SyntaxError('Unterminated array literal.', LBRACKET.span);
    } else
      return null;
  }
}
