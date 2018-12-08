import 'package:charcode/ascii.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:string_scanner/string_scanner.dart';
import 'query.dart';

final DateFormat dateYmd = new DateFormat('yyyy-MM-dd');
final DateFormat dateYmdHms = new DateFormat('yyyy-MM-dd HH:mm:ss');

/// Cleans an input SQL expression of common SQL injection points.
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
  String get columnName;

  bool get hasValue;

  String compile();

  void isBetween(T lower, T upper);

  void isNotBetween(T lower, T upper);

  void isIn(Iterable<T> values);

  void isNotIn(Iterable<T> values);
}

class NumericSqlExpressionBuilder<T extends num>
    implements SqlExpressionBuilder<T> {
  final String columnName;
  bool _hasValue = false;
  String _op = '=';
  String _raw;
  T _value;

  NumericSqlExpressionBuilder(this.columnName);

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

class StringSqlExpressionBuilder implements SqlExpressionBuilder<String> {
  final String columnName;
  bool _hasValue = false;
  String _op = '=', _raw, _value;

  StringSqlExpressionBuilder(this.columnName);

  @override
  bool get hasValue => _hasValue;

  bool _change(String op, String value) {
    _raw = null;
    _op = op;
    _value = value;
    return _hasValue = true;
  }

  @override
  String compile() {
    if (_raw != null) return _raw;
    if (_value == null) return null;
    var v = toSql(_value);
    return "$_op $v";
  }

  void isEmpty() => equals('');

  void equals(String value) {
    _change('=', value);
  }

  void notEquals(String value) {
    _change('!=', value);
  }

  void like(String value) {
    _change('LIKE', value);
  }

  @override
  void isBetween(String lower, String upper) {
    var l = sanitizeExpression(lower), u = sanitizeExpression(upper);
    _raw = "BETWEEN '$l' AND '$u'";
    _hasValue = true;
  }

  @override
  void isNotBetween(String lower, String upper) {
    var l = sanitizeExpression(lower), u = sanitizeExpression(upper);
    _raw = "NOT BETWEEN '$l' AND '$u'";
    _hasValue = true;
  }

  @override
  void isIn(Iterable<String> values) {
    _raw = 'IN (' +
        values.map(sanitizeExpression).map((s) => "'$s'").join(', ') +
        ')';
    _hasValue = true;
  }

  @override
  void isNotIn(Iterable<String> values) {
    _raw = 'NOT IN (' +
        values.map(sanitizeExpression).map((s) => "'$s'").join(', ') +
        ')';
    _hasValue = true;
  }
}

class BooleanSqlExpressionBuilder implements SqlExpressionBuilder<bool> {
  final String columnName;
  bool _hasValue = false;
  String _op = '=', _raw;
  bool _value;

  BooleanSqlExpressionBuilder(this.columnName);

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

class DateTimeSqlExpressionBuilder implements SqlExpressionBuilder<DateTime> {
  final NumericSqlExpressionBuilder<int> year =
          new NumericSqlExpressionBuilder<int>('year'),
      month = new NumericSqlExpressionBuilder<int>('month'),
      day = new NumericSqlExpressionBuilder<int>('day'),
      hour = new NumericSqlExpressionBuilder<int>('hour'),
      minute = new NumericSqlExpressionBuilder<int>('minute'),
      second = new NumericSqlExpressionBuilder<int>('second');
  final String columnName;
  String _raw;

  DateTimeSqlExpressionBuilder(this.columnName);

  @override
  bool get hasValue =>
      _raw?.isNotEmpty == true ||
      year.hasValue ||
      month.hasValue ||
      day.hasValue ||
      hour.hasValue ||
      minute.hasValue ||
      second.hasValue;

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
    if (year.hasValue) parts.add('YEAR($columnName) ${year.compile()}');
    if (month.hasValue) parts.add('MONTH($columnName) ${month.compile()}');
    if (day.hasValue) parts.add('DAY($columnName) ${day.compile()}');
    if (hour.hasValue) parts.add('HOUR($columnName) ${hour.compile()}');
    if (minute.hasValue) parts.add('MINUTE($columnName) ${minute.compile()}');
    if (second.hasValue) parts.add('SECOND($columnName) ${second.compile()}');

    return parts.isEmpty ? null : parts.join(' AND ');
  }
}
