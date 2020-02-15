import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'token.dart';

class Array extends Expression {
  final Token lBracket, rBracket;
  final List<Expression> items;

  Array(this.lBracket, this.rBracket, this.items);

  @override
  compute(scope) => items.map((e) => e.compute(scope)).toList();

  @override
  FileSpan get span {
    return items
        .fold<FileSpan>(lBracket.span, (out, i) => out.expand(i.span))
        .expand(rBracket.span);
  }
}

class IndexerExpression extends Expression {
  final Expression target, indexer;
  final Token lBracket, rBracket;

  IndexerExpression(this.target, this.lBracket, this.indexer, this.rBracket);

  @override
  FileSpan get span {
    return target.span
        .expand(lBracket.span)
        .expand(indexer.span)
        .expand(rBracket.span);
  }

  @override
  compute(scope) {
    var a = target.compute(scope), b = indexer.compute(scope);
    return a[b];
  }
}
