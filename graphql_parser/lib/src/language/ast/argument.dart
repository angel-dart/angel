import 'package:source_span/source_span.dart';
import '../token.dart';
import 'node.dart';
import 'input_value.dart';

class ArgumentContext extends Node {
  final Token NAME, COLON;
  final InputValueContext value;

  ArgumentContext(this.NAME, this.COLON, this.value);

  /// Use [value] instead.
  @deprecated
  InputValueContext get valueOrVariable => value;

  String get name => NAME.text;

  @override
  FileSpan get span => NAME.span.expand(COLON.span).expand(value.span);
}
