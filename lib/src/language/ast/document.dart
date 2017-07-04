import 'definition.dart';
import 'node.dart';
import 'package:source_span/src/span.dart';

class DocumentContext extends Node {
  final List<DefinitionContext> definitions = [];

  @override
  SourceSpan get span {
    if (definitions.isEmpty) return null;
    return definitions
        .map<SourceSpan>((d) => d.span)
        .reduce((a, b) => a.union(b));
  }

  @override
  String toSource() {
    if (definitions.isEmpty) return '(empty document)';
    return definitions.map((d) => d.toSource()).join();
  }
}
