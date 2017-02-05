part of graphql_parser.language.parser;

abstract class BaseParser implements StreamConsumer<Token> {
  final StreamController<ArrayValueContext> _onArrayValue =
      new StreamController<ArrayValueContext>();
  final StreamController<BooleanValueContext> _onBooleanValue =
      new StreamController<BooleanValueContext>();
  final StreamController<DocumentContext> _onDocument =
      new StreamController<DocumentContext>();
  final StreamController<Node> _onNode = new StreamController<Node>();
  final StreamController<NumberValueContext> _onNumberValue =
      new StreamController<NumberValueContext>();
  final StreamController<StringValueContext> _onStringValue =
      new StreamController<StringValueContext>();
  final StreamController<ValueContext> _onValue =
      new StreamController<ValueContext>();

  Stream<Node> get onArrayValue => _onArrayValue.stream;
  Stream<Node> get onBooleanValue => _onBooleanValue.stream;
  Stream<Node> get onDocument => _onDocument.stream;
  Stream<Node> get onNode => _onNode.stream;
  Stream<Node> get onNumberValue => _onNumberValue.stream;
  Stream<Node> get onStringValue => _onStringValue.stream;
  Stream<Node> get onValue => _onValue.stream;
}
