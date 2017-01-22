import 'argument.dart';
import 'directive.dart';
import 'field_name.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'selection_set.dart';

class FieldContext extends Node {
  final FieldNameContext fieldName;
  final List<ArgumentContext> arguments = [];
  final List<DirectiveContext> directives = [];
  final SelectionSetContext selectionSet;

  FieldContext(this.fieldName, [this.selectionSet]);

  @override
  SourceSpan get span {
    SourceLocation end = fieldName.end;

    if (selectionSet != null)
      end = selectionSet.end;
    else if (directives.isNotEmpty)
      end = directives.last.end;
    else if (arguments.isNotEmpty) end = arguments.last.end;

    return new SourceSpan(fieldName.start, end, toSource());
  }

  @override
  String toSource() =>
      fieldName.toSource() +
      arguments.map((a) => a.toSource()).join() +
      directives.map((d) => d.toSource()).join() +
      (selectionSet?.toSource() ?? '');
}
