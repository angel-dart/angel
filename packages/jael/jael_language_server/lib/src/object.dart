import 'dart:collection';

import 'package:source_span/source_span.dart';

abstract class JaelObject {
  final FileSpan span;
  final usages = <SymbolUsage>[];
  String get name;

  JaelObject(this.span);
}

class JaelCustomElement extends JaelObject {
  final String name;
  final attributes = new SplayTreeSet<String>();

  JaelCustomElement(this.name, FileSpan span) : super(span);
}

class JaelVariable extends JaelObject {
  final String name;
  JaelVariable(this.name, FileSpan span) : super(span);
}

class SymbolUsage {
  final SymbolUsageType type;
  final FileSpan span;

  SymbolUsage(this.type, this.span);
}

enum SymbolUsageType { definition, read }
