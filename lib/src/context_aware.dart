import 'package:matcher/matcher.dart';

/// Returns a [ContextAwareMatcher] for the given predicate.
ContextAwareMatcher predicateWithContext(
    bool Function(Object, String, Map, Map) f,
    [String description = 'satisfies function']) {
  return _PredicateWithContext(f, description);
}

/// Wraps [x] in a [ContextAwareMatcher].
ContextAwareMatcher wrapContextAwareMatcher(x) {
  if (x is ContextAwareMatcher) {
    return x;
  } else if (x is Matcher) return _WrappedContextAwareMatcher(x);
  return wrapContextAwareMatcher(wrapMatcher(x));
}

/// A special [Matcher] that is aware of the context in which it is being executed.
abstract class ContextAwareMatcher extends Matcher {
  bool matchesWithContext(item, String key, Map context, Map matchState);

  @override
  bool matches(item, Map matchState) => true;
}

class _WrappedContextAwareMatcher extends ContextAwareMatcher {
  final Matcher matcher;

  _WrappedContextAwareMatcher(this.matcher);

  @override
  Description describe(Description description) =>
      matcher.describe(description);

  @override
  bool matchesWithContext(item, String key, Map context, Map matchState) =>
      matcher.matches(item, matchState);
}

class _PredicateWithContext extends ContextAwareMatcher {
  final bool Function(Object, String, Map, Map) f;
  final String desc;

  _PredicateWithContext(this.f, this.desc);

  @override
  Description describe(Description description) =>
      desc == null ? description : description.add(desc);

  @override
  bool matchesWithContext(item, String key, Map context, Map matchState) =>
      f(item, key, context, matchState);
}
