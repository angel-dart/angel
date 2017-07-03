import 'package:test/test.dart';
import 'argument_test.dart' as argument;
import 'directive_test.dart' as directive;
import 'value_test.dart' as value;
import 'variable_test.dart' as variable;

main() {
  group('argument', argument.main);
  group('directive', directive.main);
  group('value', value.main);
  group('variable', variable.main);
}
