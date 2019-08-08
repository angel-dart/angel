import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';

class VariableContext extends InputValueContext<Object> {
  final Token DOLLAR, NAME;

  VariableContext(this.DOLLAR, this.NAME);

  String get name => NAME.text;

  @override
  FileSpan get span => DOLLAR.span.expand(NAME.span);

  @override
  Object computeValue(Map<String, dynamic> variables) => variables[name];
  // FileSpan(DOLLAR?.span?.start, NAME?.span?.end, toSource());
}
