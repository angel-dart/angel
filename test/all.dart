import 'package:test/test.dart';
import 'argument_test.dart' as argument;
import 'directive_test.dart' as directive;
import 'document_test.dart' as document;
import 'field_test.dart' as field;
import 'fragment_spread_test.dart' as fragment_spread;
import 'inline_fragment_test.dart' as inline_fragment;
import 'selection_set_test.dart' as selection_set;
import 'type_test.dart' as type;
import 'value_test.dart' as value;
import 'variable_definition_test.dart' as variable_definition;
import 'variable_test.dart' as variable;

main() {
  group('argument', argument.main);
  group('directive', directive.main);
  group('document', document.main);
  group('field', field.main);
  group('fragment spread', fragment_spread.main);
  group('inline fragment', inline_fragment.main);
  group('selection set', selection_set.main);
  group('type', type.main);
  group('value', value.main);
  group('variable', variable.main);
  group('variable definition', variable_definition.main);
}
