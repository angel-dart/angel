import 'package:test/test.dart';
import 'argument_test.dart' as argument;
import 'directive_test.dart' as directive;
import 'field_test.dart' as field;
import 'type_test.dart' as type;
import 'value_test.dart' as value;
import 'variable_definition_test.dart' as variable_definition;
import 'variable_test.dart' as variable;

main() {
  group('argument', argument.main);
  group('directive', directive.main);
  group('field', field.main);
  group('type', type.main);
  group('value', value.main);
  group('variable', variable.main);
  group('variable definition', variable_definition.main);
}
