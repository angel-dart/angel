import 'package:intl/intl.dart';


final DateFormat DATE_YMD = new DateFormat('yyyy-MM-dd');
final DateFormat DATE_YMD_HMS = new DateFormat('yyyy-MM-dd HH:mm:ss');

abstract class SqlExpressionBuilder {
  bool get hasValue;
  String compile();
}

class NumericSqlExpressionBuilder<T extends num>
    implements SqlExpressionBuilder {
  bool _hasValue = false;
  String _op = '=';
  T _value;

  @override
  bool get hasValue => _hasValue;

  bool _change(String op, T value) {
    _op = op;
    _value = value;
    return _hasValue = true;
  }

  @override
  String compile() {
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
}

// TODO: Escape SQL Strings
class StringSqlExpressionBuilder implements SqlExpressionBuilder {
  bool _hasValue = false;
  String _op = '=';
  String _value;

  @override
  bool get hasValue => _hasValue;

  bool _change(String op, String value) {
    _op = op;
    _value = value;
    return _hasValue = true;
  }

  @override
  String compile() {
    if (_value == null) return null;
    return '$_op `$_value`';
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
}

class BooleanSqlExpressionBuilder implements SqlExpressionBuilder {
  bool _hasValue = false;
  String _op = '=';
  bool _value;

  @override
  bool get hasValue => _hasValue;

  bool _change(String op, bool value) {
    _op = op;
    _value = value;
    return _hasValue = true;
  }

  @override
  String compile() {
    if (_value == null) return null;
    var v = _value ? 1 : 0;
    return '$_op $v';
  }

  void equals(bool value) {
    _change('=', value);
  }

  void notEquals(bool value) {
    _change('!=', value);
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
    _raw = '`$columnName` $_op \'$dateString\'';
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
  String compile() {
    if (_raw?.isNotEmpty == true) return _raw;
    List<String> parts = [];
    if (year.hasValue) parts.add('YEAR(`$columnName`) ${year.compile()}');
    if (month.hasValue) parts.add('MONTH(`$columnName`) ${month.compile()}');
    if (day.hasValue) parts.add('DAY(`$columnName`) ${day.compile()}');
    if (hour.hasValue) parts.add('HOUR(`$columnName`) ${hour.compile()}');
    if (minute.hasValue) parts.add('MINUTE(`$columnName`) ${minute.compile()}');
    if (second.hasValue) parts.add('SECOND(`$columnName`) ${second.compile()}');

    return parts.isEmpty ? null : parts.join(' AND ');
  }
}
