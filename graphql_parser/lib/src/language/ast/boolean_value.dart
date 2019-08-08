import 'package:source_span/source_span.dart';
import 'input_value.dart';
import '../token.dart';

/// A GraphQL boolean value literal.
class BooleanValueContext extends InputValueContext<bool> {
  bool _valueCache;

  /// The source token.
  final Token boolean;

  BooleanValueContext(this.boolean) {
    assert(boolean?.text == 'true' || boolean?.text == 'false');
  }

  /// The [bool] value of this literal.
  bool get booleanValue => _valueCache ??= boolean.text == 'true';

  /// Use [boolean] instead.
  @deprecated
  Token get BOOLEAN => boolean;

  @override
  FileSpan get span => boolean.span;

  @override
  bool computeValue(Map<String, dynamic> variables) => booleanValue;
}
