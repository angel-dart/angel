import '../token.dart';
import 'directive.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';

class FragmentSpreadContext extends Node {
  final Token ELLIPSIS, NAME;
  final List<DirectiveContext> directives = [];

  FragmentSpreadContext(this.ELLIPSIS, this.NAME);

  @override
  SourceSpan get span {
    SourceLocation end;
    return new SourceSpan(ELLIPSIS.span?.start, end, toSource());
  }

  @override
  String toSource() {
    return '...${NAME.text}' + directives.map((d) => d.toSource()).join();
  }
}
