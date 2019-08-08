import '../token.dart';
import 'definition.dart';
import 'directive.dart';
import 'package:source_span/source_span.dart';
import 'selection_set.dart';
import 'type_condition.dart';

/// A GraphQL query fragment definition.
class FragmentDefinitionContext extends ExecutableDefinitionContext {
  /// The source tokens.
  final Token fragmentToken, nameToken, onToken;

  /// The type to which this fragment applies.
  final TypeConditionContext typeCondition;

  /// Any directives on the fragment.
  final List<DirectiveContext> directives = [];

  /// The selections to apply when the [typeCondition] is met.
  final SelectionSetContext selectionSet;

  /// The [String] value of the [nameToken].
  String get name => nameToken.text;

  FragmentDefinitionContext(this.fragmentToken, this.nameToken, this.onToken,
      this.typeCondition, this.selectionSet);

  /// Use [fragmentToken] instead.
  @deprecated
  Token get FRAGMENT => fragmentToken;

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  /// Use [onToken] instead.
  @deprecated
  Token get ON => onToken;

  @override
  FileSpan get span {
    var out = fragmentToken.span
        .expand(nameToken.span)
        .expand(onToken.span)
        .expand(typeCondition.span);
    out = directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
    return out.expand(selectionSet.span);
  }
}
