import 'dart:async';
import 'ast/ast.dart';
import 'stream_reader.dart';
import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';

class Parser implements StreamConsumer<Token> {
  bool _closed = false;
  final Completer _closer = new Completer();
  final List<SyntaxError> _errors = [];
  final StreamReader<Token> _reader = new StreamReader();

  final StreamController<BooleanValueContext> _onBooleanValue =
      new StreamController<BooleanValueContext>();
  final StreamController<DocumentContext> _onDocument =
      new StreamController<DocumentContext>();
  final StreamController<Node> _onNode = new StreamController<Node>();

  List<SyntaxError> get errors => new List<SyntaxError>.unmodifiable(_errors);

  Stream<Node> get onBooleanValue => _onBooleanValue.stream;
  Stream<Node> get onDocument => _onDocument.stream;
  Stream<Node> get onNode => _onNode.stream;

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

    _reader.onData.listen((data) => _waterfall([document, booleanValue]))
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

  Future<DocumentContext> document() async {
    return null;
  }

  Future<BooleanValueContext> booleanValue() async {
    if (await nextIs(TokenType.BOOLEAN)) {
      var result = new BooleanValueContext(await _reader.consume());
      _onBooleanValue.add(result);
      return result;
    }

    return null;
  }
}
