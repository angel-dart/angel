import 'package:source_span/source_span.dart';
import 'definition.dart';
import 'node.dart';

class DocumentContext extends Node {
  final List<DefinitionContext> definitions = [];

  @override
  FileSpan get span {
    if (definitions.isEmpty) return null;
    return definitions
        .map<FileSpan>((d) => d.span)
        .reduce((a, b) => a.expand(b));
  }
}
