import 'package:source_span/source_span.dart';
import 'argument.dart';
import 'directive.dart';
import 'field_name.dart';
import 'node.dart';
import 'selection_set.dart';

class FieldContext extends Node {
  final FieldNameContext fieldName;
  final List<ArgumentContext> arguments = [];
  final List<DirectiveContext> directives = [];
  final SelectionSetContext selectionSet;

  FieldContext(this.fieldName, [this.selectionSet]);

  @override
  FileSpan get span {
    if (selectionSet != null)
      return fieldName.span.expand(selectionSet.span);
    else if (directives.isNotEmpty)
      return directives.fold<FileSpan>(
          fieldName.span, (out, d) => out.expand(d.span));
    if (arguments.isNotEmpty)
      return arguments.fold<FileSpan>(
          fieldName.span, (out, a) => out.expand(a.span));
    else
      return fieldName.span;
  }
}
