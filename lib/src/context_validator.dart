import 'package:matcher/matcher.dart';

/// A [Matcher] directly invoked by `package:angel_serialize` to validate the context.
class ContextValidator extends Matcher {
  final bool Function(String, Map) validate;
  final Description Function(Description, String, Map) errorMessage;

  ContextValidator(this.validate, this.errorMessage);

  @override
  Description describe(Description description) => description;

  @override
  bool matches(item, Map matchState) => true;
}
