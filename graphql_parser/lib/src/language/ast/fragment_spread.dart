import '../token.dart';
import 'directive.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';

class FragmentSpreadContext extends Node {
  final Token ELLIPSIS, NAME;
  final List<DirectiveContext> directives = [];

  FragmentSpreadContext(this.ELLIPSIS, this.NAME);

  String get name => NAME.text;

  @override
  FileSpan get span {
    var out = ELLIPSIS.span.expand(NAME.span);
    if (directives.isEmpty) return out;
    return directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
  }

  @override
  String toSource() {
    return '...${NAME.text}' + directives.map((d) => d.toSource()).join();
  }
}
