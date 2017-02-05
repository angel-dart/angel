library graphql_parser.language.parser;

import 'dart:async';
import 'ast/ast.dart';
import 'stream_reader.dart';
import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';
part 'base_parser.dart';

class Parser extends BaseParser {
  bool _closed = false;
  final Completer _closer = new Completer();
  final List<SyntaxError> _errors = [];
  final StreamReader<Token> _reader = new StreamReader();

  List<SyntaxError> get errors => new List<SyntaxError>.unmodifiable(_errors);

  Future _waterfall(List<Function> futures) async {
    for (var f in futures) {
      var r = await f();
      if (r != null) return r;
    }
  }

  @override
  Future addStream(Stream<Token> stream) {
    if (_closed) throw new StateError('Parser is already closed.');

    _closed = true;

    _reader.onData
        .listen((data) => _waterfall([parseDocument, parseBooleanValue]))
          ..onDone(() => Future.wait([
                _onBooleanValue.close(),
                _onDocument.close(),
                _onNode.close(),
              ]))
          ..onError(_closer.completeError);

    return stream.pipe(_reader);
  }

  @override
  Future close() {
    return _closer.future;
  }

  Future<bool> expect(TokenType type) async {
    var peek = await _reader.peek();

    if (peek?.type != type) {
      _errors.add(new SyntaxError.fromSourceLocation(
          "Expected $type, found '${peek?.text ?? 'empty text'}' instead.",
          peek?.span?.start));
      return false;
    } else {
      await _reader.consume();
      return true;
    }
  }

  Future<bool> maybe(TokenType type) async {
    var peek = await _reader.peek();

    if (peek?.type == type) {
      await _reader.consume();
      return true;
    }

    return false;
  }

  Future<bool> nextIs(TokenType type) =>
      _reader.peek().then((t) => t?.type == type);

  Future<DocumentContext> parseDocument() async {
    return null;
  }

  Future<ValueContext> parseValue() async {
    ValueContext value;

    var string = await parseStringValue();
    if (string != null)
      value = string;
    else {
      var number = await parseNumberValue();
      if (number != null)
        value = number;
      else {
        var boolean = await parseBooleanValue();
        if (boolean != null)
          value = boolean;
        else {
          var array = await parseArrayValue();
          if (array != null) value = array;
        }
      }
    }

    if (value != null) _onValue.add(value);
    return value;
  }

  Future<StringValueContext> parseStringValue() async {
    if (await nextIs(TokenType.STRING)) {
      var result = new StringValueContext(await _reader.consume());
      _onStringValue.add(result);
      return result;
    }

    return null;
  }

  Future<NumberValueContext> parseNumberValue() async {
    if (await nextIs(TokenType.NUMBER)) {
      var result = new NumberValueContext(await _reader.consume());
      _onNumberValue.add(result);
      return result;
    }

    return null;
  }

  Future<BooleanValueContext> parseBooleanValue() async {
    if (await nextIs(TokenType.BOOLEAN)) {
      var result = new BooleanValueContext(await _reader.consume());
      _onBooleanValue.add(result);
      return result;
    }

    return null;
  }

  Future<ArrayValueContext> parseArrayValue() async {
    if (await nextIs(TokenType.LBRACKET)) {
      ArrayValueContext result;
      var LBRACKET = await _reader.consume();
      List<ValueContext> values = [];

      if (await nextIs(TokenType.RBRACKET)) {
        result = new ArrayValueContext(LBRACKET, await _reader.consume());
        _onArrayValue.add(result);
        return result;
      }

      while (!_reader.isDone) {
        ValueContext value = await parseValue();
        if (value == null) break;

        values.add(value);

        if (await nextIs(TokenType.COMMA)) {
          await _reader.consume();
          continue;
        } else if (await nextIs(TokenType.RBRACKET)) {
          result = new ArrayValueContext(LBRACKET, await _reader.consume());
          _onArrayValue.add(result);
          return result;
        }

        throw new SyntaxError.fromSourceLocation(
            'Expected comma or right bracket in array',
            (await _reader.current())?.span?.start);
      }

      throw new SyntaxError.fromSourceLocation(
          'Unterminated array literal.', LBRACKET.span?.start);
    }

    if (await nextIs(TokenType.BOOLEAN)) {
      var result = new BooleanValueContext(await _reader.consume());
      _onBooleanValue.add(result);
      return result;
    }

    return null;
  }
}
