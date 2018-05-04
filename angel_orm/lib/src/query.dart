/// Expects a field to be equal to a given [value].
Predicate<T> equals<T>(T value) =>
    new Predicate<T>._(PredicateType.equals, value);

/// Expects at least one of the given [predicates] to be true.
Predicate<T> anyOf<T>(Iterable<Predicate<T>> predicates) =>
    new MultiPredicate<T>._(PredicateType.any, predicates);

/// Expects a field to be contained within a set of [values].
Predicate<T> isIn<T>(Iterable<T> values) => new Predicate<T>._(PredicateType.isIn, null, values);

/// Expects a field to be `null`.
Predicate<T> isNull<T>() => equals(null);

/// Expects a given [predicate] to not be true.
Predicate<T> not<T>(Predicate<T> predicate) =>
    new MultiPredicate<T>._(PredicateType.negate, [predicate]);

/// Expects a field to be not be `null`.
Predicate<T> notNull<T>() => not(isNull());

/// Expects a field to be less than a given [value].
Predicate<T> lessThan<T>(T value) =>
    new Predicate<T>._(PredicateType.less, value);

/// Expects a field to be less than or equal to a given [value].
Predicate<T> lessThanOrEqual<T>(T value) => lessThan(value) | equals(value);

/// Expects a field to be greater than a given [value].
Predicate<T> greaterThan<T>(T value) =>
    new Predicate<T>._(PredicateType.greater, value);

/// Expects a field to be greater than or equal to a given [value].
Predicate<T> greaterThanOrEqual<T>(T value) =>
    greaterThan(value) | equals(value);

/// A generic query class.
///
/// Angel services can translate these into driver-specific queries.
/// This allows the Angel ORM to be flexible and support multiple platforms.
class Query {
  final Map<String, Predicate> _fields = {};
  final Map<String, SortType> _sort = {};

  /// Each field in a query is actually a [Predicate], and therefore acts as a contract
  /// with the underlying service.
  Map<String, Predicate> get fields =>
      new Map<String, Predicate>.unmodifiable(_fields);

  /// The sorting order applied to this query.
  Map<String, SortType> get sorting =>
      new Map<String, SortType>.unmodifiable(_sort);

  /// Sets the [Predicate] assigned to the given [key].
  void operator []=(String key, Predicate value) => _fields[key] = value;

  /// Gets the [Predicate] assigned to the given [key].
  Predicate operator [](String key) => _fields[key];

  /// Sort output by the given [key].
  void sortBy(String key, [SortType type = SortType.descending]) =>
      _sort[key] = type;
}

/// A mechanism used to express an expectation about some object ([target]).
class Predicate<T> {
  /// The type of expectation we are declaring.
  final PredicateType type;

  /// The single argument of this target.
  final T target;
  final Iterable<T> args;

  Predicate._(this.type, this.target, [this.args]);

  Predicate<T> operator &(Predicate<T> other) => and(other);

  Predicate<T> operator |(Predicate<T> other) => or(other);

  Predicate<T> and(Predicate<T> other) {
    return new MultiPredicate._(PredicateType.and, [this, other]);
  }

  Predicate<T> or(Predicate<T> other) {
    return new MultiPredicate._(PredicateType.or, [this, other]);
  }
}

/// An advanced [Predicate] that performs an operation of multiple other predicates.
class MultiPredicate<T> extends Predicate<T> {
  final Iterable<Predicate<T>> targets;

  MultiPredicate._(PredicateType type, this.targets) : super._(type, null);

  /// Use [targets] instead.
  @deprecated
  T get target => throw new UnsupportedError(
      'IterablePredicate has no `target`. Use `targets` instead.');
}

/// The various types of predicate.
enum PredicateType {
  equals,
  any,
  isIn,
  negate,
  and,
  or,
  less,
  greater,
}

/// The various modes of sorting.
enum SortType { ascending, descending }
