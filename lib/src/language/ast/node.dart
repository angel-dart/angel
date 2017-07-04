import 'package:source_span/source_span.dart';

abstract class Node {
  SourceSpan get span;

  SourceLocation get start => span.start;
  SourceLocation get end => span.end;

  String toSource();
}
