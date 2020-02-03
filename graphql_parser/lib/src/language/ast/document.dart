import 'package:source_span/source_span.dart';
import 'definition.dart';
import 'node.dart';

/// A GraphQL document.
class DocumentContext extends Node {
  /// The top-level definitions in the document.
  final List<DefinitionContext> definitions = [];

  @override
  FileSpan get span {
    if (definitions.isEmpty) return null;
    return definitions
        .map<FileSpan>((d) => d.span)
        .reduce((a, b) => a.expand(b));
  }
}
