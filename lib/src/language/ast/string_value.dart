import '../token.dart';
import 'package:source_span/src/span.dart';
import 'value.dart';

class StringValueContext extends ValueContext {
  final Token STRING;

  StringValueContext(this.STRING);

  @override
  SourceSpan get span => STRING.span;

  String get stringValue => STRING.text.substring(0, STRING.text.length - 1);

  @override
  String toSource() => STRING.text;
}
