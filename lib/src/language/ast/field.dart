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
    if (selectionSet != null)
      return fieldName.span.union(selectionSet.span);
    else if (directives.isNotEmpty)
      return directives.fold<SourceSpan>(
          fieldName.span, (out, d) => out.union(d.span));
    if (arguments.isNotEmpty)
      return arguments.fold<SourceSpan>(
          fieldName.span, (out, a) => out.union(a.span));
    else
      return fieldName.span;
  }

  @override
  String toSource() => span.text;
}
