import 'package:source_span/source_span.dart';
import 'token.dart';

class SyntaxError implements Exception {
  final String message;
  final int line, column;
  final Token offendingToken;

  SyntaxError(this.message, this.line, this.column, [this.offendingToken]);

  factory SyntaxError.fromSourceLocation(
          String message, SourceLocation location,
          [Token offendingToken]) =>
      new SyntaxError(message, location.line, location.column, offendingToken);

  @override
  String toString() => 'Syntax error at line $line, column $column: $message';
}
