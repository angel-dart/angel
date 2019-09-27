import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:matcher/matcher.dart';
import 'context_aware.dart';

/// Returns an [AngelMatcher] that uses an arbitrary function that returns
/// true or false for the actual value.
///
/// Analogous to the synchronous [predicate] matcher.
AngelMatcher predicateWithAngel(
        FutureOr<bool> Function(String, Object, Angel) f,
        [String description = 'satisfies function']) =>
    _PredicateWithAngel(f, description);

/// Returns an [AngelMatcher] that applies an asynchronously-created [Matcher]
/// to the input.
///
/// Use this to match values against configuration, injections, etc.
AngelMatcher matchWithAngel(FutureOr<Matcher> Function(Object, Map, Angel) f,
        [String description = 'satisfies asynchronously created matcher']) =>
    _MatchWithAngel(f, description);

/// Calls [matchWithAngel] without the initial parameter.
AngelMatcher matchWithAngelBinary(
        FutureOr<Matcher> Function(Map context, Angel) f,
        [String description = 'satisfies asynchronously created matcher']) =>
    matchWithAngel((_, context, app) => f(context, app));

/// Calls [matchWithAngel] without the initial two parameters.
AngelMatcher matchWithAngelUnary(FutureOr<Matcher> Function(Angel) f,
        [String description = 'satisfies asynchronously created matcher']) =>
    matchWithAngelBinary((_, app) => f(app));

/// Calls [matchWithAngel] without any parameters.
AngelMatcher matchWithAngelNullary(FutureOr<Matcher> Function() f,
        [String description = 'satisfies asynchronously created matcher']) =>
    matchWithAngelUnary((_) => f());

/// Returns an [AngelMatcher] that represents [x].
///
/// If [x] is an [AngelMatcher], then it is returned, unmodified.
AngelMatcher wrapAngelMatcher(x) {
  if (x is AngelMatcher) return x;
  if (x is ContextAwareMatcher) return _WrappedAngelMatcher(x);
  return wrapAngelMatcher(wrapContextAwareMatcher(x));
}

/// Returns an [AngelMatcher] that asynchronously resolves a [feature], builds a [matcher], and executes it.
AngelMatcher matchAsync(FutureOr<Matcher> Function(String, Object) matcher,
    FutureOr Function() feature,
    [String description = 'satisfies asynchronously created matcher']) {
  return _MatchAsync(matcher, feature, description);
}

/// Returns an [AngelMatcher] that verifies that an item with the given [idField]
/// exists in the service at [servicePath], without throwing a `404` or returning `null`.
AngelMatcher idExistsInService(String servicePath,
    {String idField = 'id', String description}) {
  return predicateWithAngel(
    (key, item, app) async {
      try {
        var result = await app.findService(servicePath)?.read(item);
        return result != null;
      } on AngelHttpException catch (e) {
        if (e.statusCode == 404) {
          return false;
        } else {
          rethrow;
        }
      }
    },
    description ?? 'exists in service $servicePath',
  );
}

/// An asynchronous [Matcher] that runs in the context of an [Angel] app.
abstract class AngelMatcher extends ContextAwareMatcher {
  Future<bool> matchesWithAngel(
      item, String key, Map context, Map matchState, Angel app);

  @override
  bool matchesWithContext(item, String key, Map context, Map matchState) {
    return true;
  }
}

class _WrappedAngelMatcher extends AngelMatcher {
  final ContextAwareMatcher matcher;

  _WrappedAngelMatcher(this.matcher);

  @override
  Description describe(Description description) =>
      matcher.describe(description);

  @override
  Future<bool> matchesWithAngel(
      item, String key, Map context, Map matchState, Angel app) async {
    return matcher.matchesWithContext(item, key, context, matchState);
  }
}

class _MatchWithAngel extends AngelMatcher {
  final FutureOr<Matcher> Function(Object, Map, Angel) f;
  final String description;

  _MatchWithAngel(this.f, this.description);

  @override
  Description describe(Description description) => this.description == null
      ? description
      : description.add(this.description);

  @override
  Future<bool> matchesWithAngel(
      item, String key, Map context, Map matchState, Angel app) {
    return Future.sync(() => f(item, context, app)).then((result) {
      return result.matches(item, matchState);
    });
  }
}

class _PredicateWithAngel extends AngelMatcher {
  final FutureOr<bool> Function(String, Object, Angel) predicate;
  final String description;

  _PredicateWithAngel(this.predicate, this.description);

  @override
  Description describe(Description description) => this.description == null
      ? description
      : description.add(this.description);

  @override
  Future<bool> matchesWithAngel(
      item, String key, Map context, Map matchState, Angel app) {
    return Future<bool>.sync(() => predicate(key, item, app));
  }
}

class _MatchAsync extends AngelMatcher {
  final FutureOr<Matcher> Function(String, Object) matcher;
  final FutureOr Function() feature;
  final String description;

  _MatchAsync(this.matcher, this.feature, this.description);

  @override
  Description describe(Description description) => this.description == null
      ? description
      : description.add(this.description);

  @override
  Future<bool> matchesWithAngel(
      item, String key, Map context, Map matchState, Angel app) async {
    var f = await feature();
    var m = await matcher(key, f);
    var c = wrapAngelMatcher(m);
    return await c.matchesWithAngel(item, key, context, matchState, app);
  }
}
