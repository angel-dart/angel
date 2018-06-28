import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:matcher/matcher.dart';

/// Returns an [AngelMatcher] that uses an arbitrary function that returns
/// true or false for the actual value.
///
/// Analogous to the synchronous [predicate] matcher.
///
/// For example:
///
///     expect(v, predicate((x) => ((x % 2) == 0), "is even"))
AngelMatcher predicateWithAngel(FutureOr<bool> Function(Object, Angel) f,
        [String description = 'satisfies function']) =>
    new _PredicateWithAngel(f, description);

/// Returns an [AngelMatcher] that applies an asynchronously-created [Matcher]
/// to the input.
///
/// Use this to match values against configuration, injections, etc.
AngelMatcher matchWithAngel(FutureOr<Matcher> Function(Object, Angel) f,
        [String description = 'satisfies asynchronously created matcher']) =>
    new _MatchWithAngel(f, description);

/// Calls [matchWithAngel] without the initial parameter.
AngelMatcher matchWithAngelUnary(FutureOr<Matcher> Function(Angel) f,
        [String description = 'satisfies asynchronously created matcher']) =>
    matchWithAngel((_, app) => f(app));

/// Returns an [AngelMatcher] that represents [x].
///
/// If [x] is an [AngelMatcher], then it is returned, unmodified.
AngelMatcher wrapAngelMatcher(x) {
  if (x is AngelMatcher) return x;
  return matchWithAngel((_, app) => wrapMatcher(x));
}

/// Returns an [AngelMatcher] that asynchronously resolves a [feature], builds a [matcher], and executes it.
AngelMatcher matchAsync(
    FutureOr<Matcher> Function(Object) matcher, FutureOr Function() feature,
    [String description = 'satisfies asynchronously created matcher']) {
  return new _MatchAsync(matcher, feature, description);
}

/// Returns an [AngelMatcher] that verifies that an item with the given [idField]
/// exists in the service at [servicePath], without throwing a `404` or returning `null`.
AngelMatcher idExistsInService(String servicePath,
    {String idField: 'id', String description}) {
  return predicateWithAngel(
    (item, app) async {
      try {
        var result = await app.service(servicePath)?.read(item);
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
abstract class AngelMatcher extends Matcher {
  Future<bool> matchesAsync(item, Map matchState, Angel app);

  @override
  bool matches(item, Map matchState) {
    return true;
  }
}

class _MatchWithAngel extends AngelMatcher {
  final FutureOr<Matcher> Function(Object, Angel) f;
  final String description;

  _MatchWithAngel(this.f, this.description);

  @override
  Description describe(Description description) => this.description == null
      ? description
      : description.add(this.description);

  @override
  Future<bool> matchesAsync(item, Map matchState, Angel app) {
    return new Future.sync(() => f(item, app)).then((result) {
      return result.matches(item, matchState);
    });
  }
}

class _PredicateWithAngel extends AngelMatcher {
  final FutureOr<bool> Function(Object, Angel) predicate;
  final String description;

  _PredicateWithAngel(this.predicate, this.description);

  @override
  Description describe(Description description) => this.description == null
      ? description
      : description.add(this.description);

  @override
  Future<bool> matchesAsync(item, Map matchState, Angel app) {
    return new Future<bool>.sync(() => predicate(item, app));
  }
}

class _MatchAsync extends AngelMatcher {
  final FutureOr<Matcher> Function(Object) matcher;
  final FutureOr Function() feature;
  final String description;

  _MatchAsync(this.matcher, this.feature, this.description);

  @override
  Description describe(Description description) => this.description == null
      ? description
      : description.add(this.description);

  @override
  Future<bool> matchesAsync(item, Map matchState, Angel app) async {
    var f = await feature();
    var m = await matcher(f);
    return m.matches(item, matchState);
  }
}
