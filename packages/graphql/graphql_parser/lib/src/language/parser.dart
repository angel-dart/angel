library graphql_parser.language.parser;

import 'ast/ast.dart';
import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';

class Parser {
  Token _current;
  int _index = -1;

  final List<Token> tokens;
  final List<SyntaxError> errors = <SyntaxError>[];

  Parser(this.tokens);

  Token get current => _current;

  bool next(TokenType type, {Iterable<String> exclude}) {
    var tok = peek();
    if (tok?.type == type && exclude?.contains(tok.span.text) != true) {
      _current = tokens[++_index];
      return true;
    }

    return false;
  }

  bool nextName(String name) {
    var tok = peek();
    if (tok?.type == TokenType.NAME && tok.span.text == name) {
      return next(TokenType.NAME);
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

  void eatCommas() {
    while (next(TokenType.COMMA)) {
      continue;
    }
  }

  DocumentContext parseDocument() {
    List<DefinitionContext> defs = [];
    DefinitionContext def = parseDefinition();

    while (def != null) {
      defs.add(def);
      def = parseDefinition();
    }

    return DocumentContext()..definitions.addAll(defs);
  }

  DefinitionContext parseDefinition() =>
      parseOperationDefinition() ?? parseFragmentDefinition();

  OperationDefinitionContext parseOperationDefinition() {
    var selectionSet = parseSelectionSet();
    if (selectionSet != null) {
      return OperationDefinitionContext(null, null, null, selectionSet);
    } else {
      if (nextName('mutation') ||
          nextName('query') ||
          nextName('subscription')) {
        var TYPE = current;
        Token NAME = next(TokenType.NAME) ? current : null;
        var variables = parseVariableDefinitions();
        var dirs = parseDirectives();
        var selectionSet = parseSelectionSet();
        if (selectionSet != null) {
          return OperationDefinitionContext(TYPE, NAME, variables, selectionSet)
            ..directives.addAll(dirs);
        } else {
          errors.add(SyntaxError(
              'Missing selection set in fragment definition.',
              NAME?.span ?? TYPE.span));
          return null;
        }
      } else {
        return null;
      }
    }
  }

  FragmentDefinitionContext parseFragmentDefinition() {
    if (nextName('fragment')) {
      var FRAGMENT = current;
      if (next(TokenType.NAME)) {
        var NAME = current;
        if (nextName('on')) {
          var ON = current;
          var typeCondition = parseTypeCondition();
          if (typeCondition != null) {
            var dirs = parseDirectives();
            var selectionSet = parseSelectionSet();
            if (selectionSet != null) {
              return FragmentDefinitionContext(
                  FRAGMENT, NAME, ON, typeCondition, selectionSet)
                ..directives.addAll(dirs);
            } else {
              errors.add(SyntaxError(
                  'Expected selection set in fragment definition.',
                  typeCondition.span));
              return null;
            }
          } else {
            errors.add(SyntaxError(
                'Expected type condition after "on" in fragment definition.',
                ON.span));
            return null;
          }
        } else {
          errors.add(SyntaxError(
              'Expected "on" after name "${NAME.text}" in fragment definition.',
              NAME.span));
          return null;
        }
      } else {
        errors.add(SyntaxError(
            'Expected name after "fragment" in fragment definition.',
            FRAGMENT.span));
        return null;
      }
    } else {
      return null;
    }
  }

  FragmentSpreadContext parseFragmentSpread() {
    if (next(TokenType.ELLIPSIS)) {
      var ELLIPSIS = current;
      if (next(TokenType.NAME, exclude: ['on'])) {
        var NAME = current;
        return FragmentSpreadContext(ELLIPSIS, NAME)
          ..directives.addAll(parseDirectives());
      } else {
        _index--;
        return null;
      }
    } else {
      return null;
    }
  }

  InlineFragmentContext parseInlineFragment() {
    if (next(TokenType.ELLIPSIS)) {
      var ELLIPSIS = current;
      if (nextName('on')) {
        var ON = current;
        var typeCondition = parseTypeCondition();
        if (typeCondition != null) {
          var directives = parseDirectives();
          var selectionSet = parseSelectionSet();
          if (selectionSet != null) {
            return InlineFragmentContext(
                ELLIPSIS, ON, typeCondition, selectionSet)
              ..directives.addAll(directives);
          } else {
            errors.add(SyntaxError(
                'Missing selection set in inline fragment.',
                directives.isEmpty
                    ? typeCondition.span
                    : directives.last.span));
            return null;
          }
        } else {
          errors.add(SyntaxError(
              'Missing type condition after "on" in inline fragment.',
              ON.span));
          return null;
        }
      } else {
        errors.add(SyntaxError(
            'Missing "on" after "..." in inline fragment.', ELLIPSIS.span));
        return null;
      }
    } else {
      return null;
    }
  }

  SelectionSetContext parseSelectionSet() {
    if (next(TokenType.LBRACE)) {
      var LBRACE = current;
      List<SelectionContext> selections = [];
      SelectionContext selection = parseSelection();

      while (selection != null) {
        selections.add(selection);
        eatCommas();
        selection = parseSelection();
      }

      eatCommas();
      if (next(TokenType.RBRACE)) {
        return SelectionSetContext(LBRACE, current)
          ..selections.addAll(selections);
      } else {
        errors.add(SyntaxError('Missing "}" after selection set.',
            selections.isEmpty ? LBRACE.span : selections.last.span));
        return null;
      }
    } else {
      return null;
    }
  }

  SelectionContext parseSelection() {
    var field = parseField();
    if (field != null) return SelectionContext(field);
    var fragmentSpread = parseFragmentSpread();
    if (fragmentSpread != null) return SelectionContext(null, fragmentSpread);
    var inlineFragment = parseInlineFragment();
    if (inlineFragment != null) {
      return SelectionContext(null, null, inlineFragment);
    } else {
      return null;
    }
  }

  FieldContext parseField() {
    var fieldName = parseFieldName();
    if (fieldName != null) {
      var args = parseArguments();
      var directives = parseDirectives();
      var selectionSet = parseSelectionSet();
      return FieldContext(fieldName, selectionSet)
        ..arguments.addAll(args ?? <ArgumentContext>[])
        ..directives.addAll(directives);
    } else {
      return null;
    }
  }

  FieldNameContext parseFieldName() {
    if (next(TokenType.NAME)) {
      var NAME1 = current;
      if (next(TokenType.COLON)) {
        var COLON = current;
        if (next(TokenType.NAME)) {
          return FieldNameContext(null, AliasContext(NAME1, COLON, current));
        } else {
          errors.add(
              SyntaxError('Missing name after colon in alias.', COLON.span));
          return null;
        }
      } else {
        return FieldNameContext(NAME1);
      }
    } else {
      return null;
    }
  }

  VariableDefinitionsContext parseVariableDefinitions() {
    if (next(TokenType.LPAREN)) {
      var LPAREN = current;
      List<VariableDefinitionContext> defs = [];
      VariableDefinitionContext def = parseVariableDefinition();

      while (def != null) {
        defs.add(def);
        eatCommas();
        def = parseVariableDefinition();
      }

      if (next(TokenType.RPAREN)) {
        return VariableDefinitionsContext(LPAREN, current)
          ..variableDefinitions.addAll(defs);
      } else {
        errors.add(SyntaxError(
            'Missing ")" after variable definitions.', LPAREN.span));
        return null;
      }
    } else {
      return null;
    }
  }

  VariableDefinitionContext parseVariableDefinition() {
    var variable = parseVariable();
    if (variable != null) {
      if (next(TokenType.COLON)) {
        var COLON = current;
        var type = parseType();
        if (type != null) {
          var defaultValue = parseDefaultValue();
          return VariableDefinitionContext(variable, COLON, type, defaultValue);
        } else {
          errors.add(
              SyntaxError('Missing type in variable definition.', COLON.span));
          return null;
        }
      } else {
        errors.add(
            SyntaxError('Missing ":" in variable definition.', variable.span));
        return null;
      }
    } else {
      return null;
    }
  }

  TypeContext parseType() {
    var name = parseTypeName();
    if (name != null) {
      return TypeContext(name, null, maybe(TokenType.EXCLAMATION));
    } else {
      var listType = parseListType();
      if (listType != null) {
        return TypeContext(null, listType, maybe(TokenType.EXCLAMATION));
      } else {
        return null;
      }
    }
  }

  ListTypeContext parseListType() {
    if (next(TokenType.LBRACKET)) {
      var LBRACKET = current;
      var type = parseType();
      if (type != null) {
        if (next(TokenType.RBRACKET)) {
          return ListTypeContext(LBRACKET, type, current);
        } else {
          errors.add(SyntaxError('Missing "]" in list type.', type.span));
          return null;
        }
      } else {
        errors.add(SyntaxError('Missing type after "[".', LBRACKET.span));
        return null;
      }
    } else {
      return null;
    }
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
          var val = parseInputValue();
          if (val != null) {
            return DirectiveContext(ARROBA, NAME, COLON, null, null, null, val);
          } else {
            errors.add(SyntaxError(
                'Missing value or variable in directive after colon.',
                COLON.span));
            return null;
          }
        } else if (next(TokenType.LPAREN)) {
          var LPAREN = current;
          var arg = parseArgument();
          if (arg != null) {
            if (next(TokenType.RPAREN)) {
              return DirectiveContext(
                  ARROBA, NAME, null, LPAREN, current, arg, null);
            } else {
              errors.add(SyntaxError('Missing \')\'', arg.value.span));
              return null;
            }
          } else {
            errors.add(
                SyntaxError('Missing argument in directive.', LPAREN.span));
            return null;
          }
        } else {
          return DirectiveContext(ARROBA, NAME, null, null, null, null, null);
        }
      } else {
        errors.add(SyntaxError('Missing name for directive.', ARROBA.span));
        return null;
      }
    } else {
      return null;
    }
  }

  List<ArgumentContext> parseArguments() {
    if (next(TokenType.LPAREN)) {
      var LPAREN = current;
      List<ArgumentContext> out = [];
      ArgumentContext arg = parseArgument();

      while (arg != null) {
        out.add(arg);
        eatCommas();
        arg = parseArgument();
      }

      if (next(TokenType.RPAREN)) {
        return out;
      } else {
        errors.add(SyntaxError('Missing ")" in argument list.', LPAREN.span));
        return null;
      }
    } else {
      return [];
    }
  }

  ArgumentContext parseArgument() {
    if (next(TokenType.NAME)) {
      var NAME = current;
      if (next(TokenType.COLON)) {
        var COLON = current;
        var val = parseInputValue();
        if (val != null) {
          return ArgumentContext(NAME, COLON, val);
        } else {
          errors.add(SyntaxError(
              'Missing value or variable in argument.', COLON.span));
          return null;
        }
      } else {
        errors.add(
            SyntaxError('Missing colon after name in argument.', NAME.span));
        return null;
      }
    } else {
      return null;
    }
  }

  /// Use [parseInputValue] instead.
  @deprecated
  InputValueContext parseValueOrVariable() => parseInputValue();

  VariableContext parseVariable() {
    if (next(TokenType.DOLLAR)) {
      var DOLLAR = current;
      if (next(TokenType.NAME)) {
        return VariableContext(DOLLAR, current);
      } else {
        errors.add(SyntaxError(
            'Missing name for variable; found a lone "\$" instead.',
            DOLLAR.span));
        return null;
      }
    } else {
      return null;
    }
  }

  DefaultValueContext parseDefaultValue() {
    if (next(TokenType.EQUALS)) {
      var EQUALS = current;
      var value = parseInputValue();
      if (value != null) {
        return DefaultValueContext(EQUALS, value);
      } else {
        errors.add(SyntaxError('Missing value after "=" sign.', EQUALS.span));
        return null;
      }
    } else {
      return null;
    }
  }

  TypeConditionContext parseTypeCondition() {
    var name = parseTypeName();
    if (name != null) {
      return TypeConditionContext(name);
    } else {
      return null;
    }
  }

  TypeNameContext parseTypeName() {
    if (next(TokenType.NAME)) {
      return TypeNameContext(current);
    } else {
      return null;
    }
  }

  /// Use [parseInputValue] instead.
  @deprecated
  InputValueContext parseValue() => parseInputValue();

  InputValueContext parseInputValue() {
    return (parseVariable() ??
        parseNumberValue() ??
        parseStringValue() ??
        parseBooleanValue() ??
        parseNullValue() ??
        parseEnumValue() ??
        parseListValue() ??
        parseObjectValue()) as InputValueContext;
  }

  StringValueContext parseStringValue() => next(TokenType.STRING)
      ? StringValueContext(current)
      : (next(TokenType.BLOCK_STRING)
          ? StringValueContext(current, isBlockString: true)
          : null);

  NumberValueContext parseNumberValue() =>
      next(TokenType.NUMBER) ? NumberValueContext(current) : null;

  BooleanValueContext parseBooleanValue() =>
      (nextName('true') || nextName('false'))
          ? BooleanValueContext(current)
          : null;

  EnumValueContext parseEnumValue() =>
      next(TokenType.NAME) ? EnumValueContext(current) : null;

  NullValueContext parseNullValue() =>
      nextName('null') ? NullValueContext(current) : null;

  ListValueContext parseListValue() {
    if (next(TokenType.LBRACKET)) {
      var LBRACKET = current;
      var lastSpan = LBRACKET.span;
      List<InputValueContext> values = [];
      var value = parseInputValue();

      while (value != null) {
        lastSpan = value.span;
        values.add(value);
        eatCommas();
        value = parseInputValue();
      }

      eatCommas();
      if (next(TokenType.RBRACKET)) {
        return ListValueContext(LBRACKET, current)..values.addAll(values);
      } else {
        errors.add(SyntaxError('Unterminated list literal.', lastSpan));
        return null;
      }
    } else {
      return null;
    }
  }

  ObjectValueContext parseObjectValue() {
    if (next(TokenType.LBRACE)) {
      var LBRACE = current;
      var lastSpan = LBRACE.span;
      var fields = <ObjectFieldContext>[];
      var field = parseObjectField();

      while (field != null) {
        fields.add(field);
        lastSpan = field.span;
        eatCommas();
        field = parseObjectField();
      }

      eatCommas();

      if (next(TokenType.RBRACE)) {
        return ObjectValueContext(LBRACE, fields, current);
      } else {
        errors.add(SyntaxError('Unterminated object literal.', lastSpan));
        return null;
      }
    } else {
      return null;
    }
  }

  ObjectFieldContext parseObjectField() {
    if (next(TokenType.NAME)) {
      var NAME = current;

      if (next(TokenType.COLON)) {
        var COLON = current;
        var value = parseInputValue();

        if (value != null) {
          return ObjectFieldContext(NAME, COLON, value);
        } else {
          errors.add(SyntaxError('Missing value after ":".', COLON.span));
          return null;
        }
      } else {
        errors.add(SyntaxError(
            'Missing ":" after name "${NAME.span.text}".', NAME.span));
        return null;
      }
    } else {
      return null;
    }
  }
}
