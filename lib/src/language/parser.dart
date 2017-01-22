import 'dart:async';
import 'ast/ast.dart';
import 'stream_reader.dart';
import 'token.dart';

class Parser implements StreamConsumer<Token> {
  bool _closed = false;
  final StreamReader<Token> _reader = new StreamReader();

  final StreamController<Node> _onNode = new StreamController<Node>();

  Stream<Node> get onNode => _onNode.stream;

  @override
  Future addStream(Stream<Token> stream) async {
    if (_closed) throw new StateError('Parser is already closed.');
    stream.pipe(_reader);
  }

  @override
  Future close() async {
    _closed = true;

    await _onNode.close();
  }
}
