import 'package:charcode/charcode.dart';
import 'package:meta/meta.dart';
import 'package:intl/intl.dart';
import 'package:string_scanner/string_scanner.dart';

final DateFormat DATE_YMD = new DateFormat('yyyy-MM-dd');
final DateFormat DATE_YMD_HMS = new DateFormat('yyyy-MM-dd HH:mm:ss');

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
    else if ((ch == scanner.readChar()) != 0) buf.writeCharCode(ch);
  }

  return buf.toString();
}

abstract class SqlExpressionBuilder {
  bool get hasValue;
  String compile();
  void isBetween(lower, upper);
  void isNotBetween(lower, upper);
  void isIn(Iterable values);
  void isNotIn(Iterable values);
}

class NumericSqlExpressionBuilder<T extends num>
    implements SqlExpressionBuilder {
  bool _hasValue = false;
  String _op = '=';
  String _raw;
  T _value;

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
  void isBetween(@checked T lower, @checked T upper) {
    _raw = 'BETWEEN $lower AND $upper';
    _hasValue = true;
  }

  @override
  void isNotBetween(@checked T lower, @checked T upper) {
    _raw = 'NOT BETWEEN $lower AND $upper';
    _hasValue = true;
  }

  @override
  void isIn(@checked Iterable<T> values) {
    _raw = 'IN (' + values.join(', ') + ')';
    _hasValue = true;
  }

  @override
  void isNotIn(@checked Iterable<T> values) {
    _raw = 'NOT IN (' + values.join(', ') + ')';
    _hasValue = true;
  }
}

class StringSqlExpressionBuilder implements SqlExpressionBuilder {
  bool _hasValue = false;
  String _op = '=', _raw, _value;

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
    var v = sanitizeExpression(_value);
    return "$_op '$v'";
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
  void isBetween(@checked String lower, @checked String upper) {
    var l = sanitizeExpression(lower), u = sanitizeExpression(upper);
    _raw = "BETWEEN '$l' AND '$u'";
    _hasValue = true;
  }

  @override
  void isNotBetween(@checked String lower, @checked String upper) {
    var l = sanitizeExpression(lower), u = sanitizeExpression(upper);
    _raw = "NOT BETWEEN '$l' AND '$u'";
    _hasValue = true;
  }

  @override
  void isIn(@checked Iterable<String> values) {
    _raw = 'IN (' +
        values.map(sanitizeExpression).map((s) => "'$s'").join(', ') +
        ')';
    _hasValue = true;
  }

  @override
  void isNotIn(@checked Iterable<String> values) {
    _raw = 'NOT IN (' +
        values.map(sanitizeExpression).map((s) => "'$s'").join(', ') +
        ')';
    _hasValue = true;
  }
}

class BooleanSqlExpressionBuilder implements SqlExpressionBuilder {
  bool _hasValue = false;
  String _op = '=', _raw;
  bool _value;

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

  void equals(bool value) {
    _change('=', value);
  }

  void notEquals(bool value) {
    _change('!=', value);
  }

  @override
  void isBetween(@checked bool lower, @checked bool upper) =>
      throw new UnsupportedError(
          'Booleans do not support BETWEEN expressions.');

  @override
  void isNotBetween(@checked bool lower, @checked bool upper) =>
      isBetween(lower, upper);

  @override
  void isIn(@checked Iterable<bool> values) {
    _raw = 'IN (' + values.map((b) => b ? 'TRUE' : 'FALSE').join(', ') + ')';
    _hasValue = true;
  }

  @override
  void isNotIn(@checked Iterable<bool> values) {
    _raw =
        'NOT IN (' + values.map((b) => b ? 'TRUE' : 'FALSE').join(', ') + ')';
    _hasValue = true;
  }
}

class DateTimeSqlExpressionBuilder implements SqlExpressionBuilder {
  final NumericSqlExpressionBuilder<int> year =
          new NumericSqlExpressionBuilder<int>(),
      month = new NumericSqlExpressionBuilder<int>(),
      day = new NumericSqlExpressionBuilder<int>(),
      hour = new NumericSqlExpressionBuilder<int>(),
      minute = new NumericSqlExpressionBuilder<int>(),
      second = new NumericSqlExpressionBuilder<int>();
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
    var dateString = time ? DATE_YMD_HMS.format(dt) : DATE_YMD.format(dt);
    _raw = '"$columnName" $_op \'$dateString\'';
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
  void isIn(@checked Iterable<DateTime> values) {
    _raw = '"$columnName" IN (' +
        values.map(DATE_YMD_HMS.format).map((s) => "'$s'").join(', ') +
        ')';
  }

  @override
  void isNotIn(@checked Iterable<DateTime> values) {
    _raw = '"$columnName" NOT IN (' +
        values.map(DATE_YMD_HMS.format).map((s) => "'$s'").join(', ') +
        ')';
  }

  @override
  void isBetween(@checked DateTime lower, @checked DateTime upper) {
    var l = DATE_YMD_HMS.format(lower), u = DATE_YMD_HMS.format(upper);
    _raw = "\"$columnName\" BETWEEN '$l' and '$u'";
  }

  @override
  void isNotBetween(@checked DateTime lower, @checked DateTime upper) {
    var l = DATE_YMD_HMS.format(lower), u = DATE_YMD_HMS.format(upper);
    _raw = "\"$columnName\" NOT BETWEEN '$l' and '$u'";
  }

  @override
  String compile() {
    if (_raw?.isNotEmpty == true) return _raw;
    List<String> parts = [];
    if (year.hasValue) parts.add('YEAR("$columnName") ${year.compile()}');
    if (month.hasValue) parts.add('MONTH("$columnName") ${month.compile()}');
    if (day.hasValue) parts.add('DAY("$columnName") ${day.compile()}');
    if (hour.hasValue) parts.add('HOUR("$columnName") ${hour.compile()}');
    if (minute.hasValue) parts.add('MINUTE("$columnName") ${minute.compile()}');
    if (second.hasValue) parts.add('SECOND("$columnName") ${second.compile()}');

    return parts.isEmpty ? null : parts.join(' AND ');
  }
}
