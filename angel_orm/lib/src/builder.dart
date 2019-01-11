import 'package:charcode/ascii.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:string_scanner/string_scanner.dart';
import 'query.dart';

final DateFormat dateYmd = new DateFormat('yyyy-MM-dd');
final DateFormat dateYmdHms = new DateFormat('yyyy-MM-dd HH:mm:ss');

/// The ORM prefers using substitution values, which allow for prepared queries,
/// and prevent SQL injection attacks.
@deprecated
String sanitizeExpression(String unsafe) {
  var buf = new StringBuffer();
  var scanner = new StringScanner(unsafe);
  int ch;

  while (!scanner.isDone) {
    // Ignore comment starts
    if (scanner.scan('--') || scanner.scan('/*'))
      continue;

    // Ignore all single quotes and attempted escape sequences
    else if (scanner.scan("'") || scanner.scan('\\'))
      continue;

    // Otherwise, add the next char, unless it's a null byte.
    else if ((ch = scanner.readChar()) != $nul && ch != null)
      buf.writeCharCode(ch);
  }

  return toSql(buf.toString(), withQuotes: false);
}

abstract class SqlExpressionBuilder<T> {
  final Query query;
  final String columnName;
  String _substitution;

  SqlExpressionBuilder(this.query, this.columnName);

  String get substitution => _substitution ??= query.reserveName(columnName);

  bool get hasValue;

  String compile();

  void isBetween(T lower, T upper);

  void isNotBetween(T lower, T upper);

  void isIn(Iterable<T> values);

  void isNotIn(Iterable<T> values);
}

class NumericSqlExpressionBuilder<T extends num>
    extends SqlExpressionBuilder<T> {
  bool _hasValue = false;
  String _op = '=';
  String _raw;
  T _value;

  NumericSqlExpressionBuilder(Query query, String columnName)
      : super(query, columnName);

  @override
  bool get hasValue => _hasValue;

  bool _change(String op, T value) {
    _raw = null;
    _op = op;
    _value = value;
    return _hasValue = true;
  }

  @override
  String compile() {
    if (_raw != null) return _raw;
    if (_value == null) return null;
    return '$_op $_value';
  }

  operator <(T value) => _change('<', value);

  operator >(T value) => _change('>', value);

  operator <=(T value) => _change('<=', value);

  operator >=(T value) => _change('>=', value);

  void lessThan(T value) {
    _change('<', value);
  }

  void lessThanOrEqualTo(T value) {
    _change('<=', value);
  }

  void greaterThan(T value) {
    _change('>', value);
  }

  void greaterThanOrEqualTo(T value) {
    _change('>=', value);
  }

  void equals(T value) {
    _change('=', value);
  }

  void notEquals(T value) {
    _change('!=', value);
  }

  @override
  void isBetween(T lower, T upper) {
    _raw = 'BETWEEN $lower AND $upper';
    _hasValue = true;
  }

  @override
  void isNotBetween(T lower, T upper) {
    _raw = 'NOT BETWEEN $lower AND $upper';
    _hasValue = true;
  }

  @override
  void isIn(Iterable<T> values) {
    _raw = 'IN (' + values.join(', ') + ')';
    _hasValue = true;
  }

  @override
  void isNotIn(Iterable<T> values) {
    _raw = 'NOT IN (' + values.join(', ') + ')';
    _hasValue = true;
  }
}

class StringSqlExpressionBuilder extends SqlExpressionBuilder<String> {
  bool _hasValue = false;
  String _op = '=', _raw, _value;

  StringSqlExpressionBuilder(Query query, String columnName)
      : super(query, columnName);

  @override
  bool get hasValue => _hasValue;

  String get lowerName => '${substitution}_lower';

  String get upperName => '${substitution}_upper';

  bool _change(String op, String value) {
    _raw = null;
    _op = op;
    _value = value;
    query.substitutionValues[substitution] = _value;
    return _hasValue = true;
  }

  @override
  String compile() {
    if (_raw != null) return _raw;
    if (_value == null) return null;
    return "$_op @$substitution";
  }

  void isEmpty() => equals('');

  void equals(String value) {
    _change('=', value);
  }

  void notEquals(String value) {
    _change('!=', value);
  }

  /// Builds a `LIKE` predicate.
  ///
  /// To prevent injections, the [pattern] is called with a name that
  /// will be escaped by the underlying [QueryExecutor].
  ///
  /// Example:
  /// ```dart
  /// carNameBuilder.like((name) => 'Mazda %$name%');
  /// ```
  void like(String Function(String) pattern) {
    _raw = 'LIKE \'' + pattern('@$substitution') + '\'';
    query.substitutionValues[substitution] = _value;
    _hasValue = true;
  }

  @override
  void isBetween(String lower, String upper) {
    query.substitutionValues[lowerName] = lower;
    query.substitutionValues[upperName] = upper;
    _raw = "BETWEEN @$lowerName AND @$upperName";
    _hasValue = true;
  }

  @override
  void isNotBetween(String lower, String upper) {
    query.substitutionValues[lowerName] = lower;
    query.substitutionValues[upperName] = upper;
    _raw = "NOT BETWEEN @$lowerName AND @$upperName";
    _hasValue = true;
  }

  String _in(Iterable<String> values) {
    return 'IN (' +
        values.map((v) {
          var name = query.reserveName('${columnName}_in_value');
          query.substitutionValues[name] = v;
          return '@$name';
        }).join(', ') +
        ')';
  }

  @override
  void isIn(Iterable<String> values) {
    _raw = _in(values);
    _hasValue = true;
  }

  @override
  void isNotIn(Iterable<String> values) {
    _raw = 'NOT ' + _in(values);
    _hasValue = true;
  }
}

class BooleanSqlExpressionBuilder extends SqlExpressionBuilder<bool> {
  bool _hasValue = false;
  String _op = '=', _raw;
  bool _value;

  BooleanSqlExpressionBuilder(Query query, String columnName)
      : super(query, columnName);

  @override
  bool get hasValue => _hasValue;

  bool _change(String op, bool value) {
    _raw = null;
    _op = op;
    _value = value;
    return _hasValue = true;
  }

  @override
  String compile() {
    if (_raw != null) return _raw;
    if (_value == null) return null;
    var v = _value ? 'TRUE' : 'FALSE';
    return '$_op $v';
  }

  Null get isTrue => equals(true);

  Null get isFalse => equals(false);

  void equals(bool value) {
    _change('=', value);
  }

  void notEquals(bool value) {
    _change('!=', value);
  }

  @override
  void isBetween(bool lower, bool upper) => throw new UnsupportedError(
      'Booleans do not support BETWEEN expressions.');

  @override
  void isNotBetween(bool lower, bool upper) => isBetween(lower, upper);

  @override
  void isIn(Iterable<bool> values) {
    _raw = 'IN (' + values.map((b) => b ? 'TRUE' : 'FALSE').join(', ') + ')';
    _hasValue = true;
  }

  @override
  void isNotIn(Iterable<bool> values) {
    _raw =
        'NOT IN (' + values.map((b) => b ? 'TRUE' : 'FALSE').join(', ') + ')';
    _hasValue = true;
  }
}

class DateTimeSqlExpressionBuilder extends SqlExpressionBuilder<DateTime> {
  NumericSqlExpressionBuilder<int> _year, _month, _day, _hour, _minute, _second;

  String _raw;

  DateTimeSqlExpressionBuilder(Query query, String columnName)
      : super(query, columnName);

  NumericSqlExpressionBuilder<int> get year =>
      _year ??= new NumericSqlExpressionBuilder(query, 'year');
  NumericSqlExpressionBuilder<int> get month =>
      _month ??= new NumericSqlExpressionBuilder(query, 'month');
  NumericSqlExpressionBuilder<int> get day =>
      _day ??= new NumericSqlExpressionBuilder(query, 'day');
  NumericSqlExpressionBuilder<int> get hour =>
      _hour ??= new NumericSqlExpressionBuilder(query, 'hour');
  NumericSqlExpressionBuilder<int> get minute =>
      _minute ??= new NumericSqlExpressionBuilder(query, 'minute');
  NumericSqlExpressionBuilder<int> get second =>
      _second ??= new NumericSqlExpressionBuilder(query, 'second');

  @override
  bool get hasValue =>
      _raw?.isNotEmpty == true ||
      _year?.hasValue == true ||
      _month?.hasValue == true ||
      _day?.hasValue == true ||
      _hour?.hasValue == true ||
      _minute?.hasValue == true ||
      _second?.hasValue == true;

  bool _change(String _op, DateTime dt, bool time) {
    var dateString = time ? dateYmdHms.format(dt) : dateYmd.format(dt);
    _raw = '$columnName $_op \'$dateString\'';
    return true;
  }

  operator <(DateTime value) => _change('<', value, true);

  operator <=(DateTime value) => _change('<=', value, true);

  operator >(DateTime value) => _change('>', value, true);

  operator >=(DateTime value) => _change('>=', value, true);

  void equals(DateTime value, {bool includeTime: true}) {
    _change('=', value, includeTime != false);
  }

  void lessThan(DateTime value, {bool includeTime: true}) {
    _change('<', value, includeTime != false);
  }

  void lessThanOrEqualTo(DateTime value, {bool includeTime: true}) {
    _change('<=', value, includeTime != false);
  }

  void greaterThan(DateTime value, {bool includeTime: true}) {
    _change('>', value, includeTime != false);
  }

  void greaterThanOrEqualTo(DateTime value, {bool includeTime: true}) {
    _change('>=', value, includeTime != false);
  }

  @override
  void isIn(Iterable<DateTime> values) {
    _raw = '$columnName IN (' +
        values.map(dateYmdHms.format).map((s) => '$s').join(', ') +
        ')';
  }

  @override
  void isNotIn(Iterable<DateTime> values) {
    _raw = '$columnName NOT IN (' +
        values.map(dateYmdHms.format).map((s) => '$s').join(', ') +
        ')';
  }

  @override
  void isBetween(DateTime lower, DateTime upper) {
    var l = dateYmdHms.format(lower), u = dateYmdHms.format(upper);
    _raw = "$columnName BETWEEN '$l' and '$u'";
  }

  @override
  void isNotBetween(DateTime lower, DateTime upper) {
    var l = dateYmdHms.format(lower), u = dateYmdHms.format(upper);
    _raw = "$columnName NOT BETWEEN '$l' and '$u'";
  }

  @override
  String compile() {
    if (_raw?.isNotEmpty == true) return _raw;
    List<String> parts = [];
    if (year?.hasValue == true)
      parts.add('YEAR($columnName) ${year.compile()}');
    if (month?.hasValue == true)
      parts.add('MONTH($columnName) ${month.compile()}');
    if (day?.hasValue == true) parts.add('DAY($columnName) ${day.compile()}');
    if (hour?.hasValue == true)
      parts.add('HOUR($columnName) ${hour.compile()}');
    if (minute?.hasValue == true)
      parts.add('MINUTE($columnName) ${minute.compile()}');
    if (second?.hasValue == true)
      parts.add('SECOND($columnName) ${second.compile()}');

    return parts.isEmpty ? null : parts.join(' AND ');
  }
}

class MapSqlExpressionBuilder<K, V, Key extends SqlExpressionBuilder<K>,
    Value extends SqlExpressionBuilder<V>> extends SqlExpressionBuilder {
  final Key key;
  final Value value;
  bool _hasValue = false;
  String _raw;

  MapSqlExpressionBuilder(Query query, String columnName, this.key, this.value)
      : super(query, columnName);

  UnsupportedError _unsupported() =>
      UnsupportedError('JSON/JSONB does not support this operation.');

  @override
  String compile() {
    var parts = <String>[_raw, key.compile(), value.compile()];
    parts.removeWhere((s) => s == null);
    return parts.isEmpty ? null : parts.join(' && ');
  }

  @override
  bool get hasValue => key.hasValue || value.hasValue || _hasValue;

  @override
  void isBetween(lower, upper) => throw _unsupported();

  @override
  void isIn(Iterable values) => throw _unsupported();

  @override
  void isNotBetween(lower, upper) => throw _unsupported();

  @override
  void isNotIn(Iterable values) => throw _unsupported();
}
