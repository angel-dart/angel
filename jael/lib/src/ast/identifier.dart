import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import 'expression.dart';
import 'token.dart';

class Identifier extends Expression {
  final Token id;

  Identifier(this.id);

  @override
  compute(SymbolTable scope) {
    switch (name) {
      case 'null':
        return null;
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        var symbol = scope.resolve(name);
        if (symbol == null) {
          if (scope.resolve('!strict!')?.value == false) return null;
          throw ArgumentError('The name "$name" does not exist in this scope.');
        }
        return scope.resolve(name).value;
    }
  }

  String get name => id.span.text;

  @override
  FileSpan get span => id.span;
}

class SyntheticIdentifier extends Identifier {
  @override
  final String name;

  SyntheticIdentifier(this.name, [Token token]) : super(token);

  @override
  FileSpan get span {
    if (id != null) return id.span;
    throw UnsupportedError('Cannot get the span of a SyntheticIdentifier.');
  }
}
