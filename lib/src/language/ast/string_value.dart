import '../token.dart';
import 'package:source_span/src/span.dart';
import 'value.dart';

class StringValueContext extends ValueContext {
  final Token STRING;

  StringValueContext(this.STRING);

  @override
  SourceSpan get span => STRING.span;

  @override
  String toSource() => STRING.text;
}
