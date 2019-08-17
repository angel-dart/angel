import 'dart:async';

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm/src/query.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'main.g.dart';
part 'main.serializer.g.dart';

main() async {
  var query = EmployeeQuery()
    ..where.firstName.equals('Rich')
    ..where.lastName.equals('Person')
    ..orWhere((w) => w.salary.greaterThanOrEqualTo(75000))
    ..join('companies', 'company_id', 'id');

  var richPerson = await query.getOne(_FakeExecutor());
  print(richPerson.toJson());
}

class _FakeExecutor extends QueryExecutor {
  const _FakeExecutor();

  @override
  Future<List<List>> query(
      String tableName, String query, Map<String, dynamic> substitutionValues,
      [returningFields]) async {
    var now = DateTime.now();
    print(
        '_FakeExecutor received query: $query and values: $substitutionValues');
    return [
      [1, 'Rich', 'Person', 100000.0, now, now]
    ];
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(QueryExecutor) f) {
    throw UnsupportedError('Transactions are not supported.');
  }
}

@orm
@serializable
abstract class _Employee extends Model {
  String get firstName;

  String get lastName;

  double get salary;
}

class EmployeeQuery extends Query<Employee, EmployeeQueryWhere> {
  @override
  final QueryValues values = MapQueryValues();

  EmployeeQueryWhere _where;

  EmployeeQuery() {
    _where = EmployeeQueryWhere(this);
  }

  @override
  EmployeeQueryWhere get where => _where;

  @override
  String get tableName => 'employees';

  @override
  List<String> get fields =>
      ['id', 'first_name', 'last_name', 'salary', 'created_at', 'updated_at'];

  @override
  EmployeeQueryWhere newWhereClause() => EmployeeQueryWhere(this);

  @override
  Employee deserialize(List row) {
    return Employee(
        id: row[0].toString(),
        firstName: row[1] as String,
        lastName: row[2] as String,
        salary: row[3] as double,
        createdAt: row[4] as DateTime,
        updatedAt: row[5] as DateTime);
  }
}

class EmployeeQueryWhere extends QueryWhere {
  EmployeeQueryWhere(EmployeeQuery query)
      : id = NumericSqlExpressionBuilder(query, 'id'),
        firstName = StringSqlExpressionBuilder(query, 'first_name'),
        lastName = StringSqlExpressionBuilder(query, 'last_name'),
        salary = NumericSqlExpressionBuilder(query, 'salary'),
        createdAt = DateTimeSqlExpressionBuilder(query, 'created_at'),
        updatedAt = DateTimeSqlExpressionBuilder(query, 'updated_at');

  @override
  Iterable<SqlExpressionBuilder> get expressionBuilders {
    return [id, firstName, lastName, salary, createdAt, updatedAt];
  }

  final NumericSqlExpressionBuilder<int> id;

  final StringSqlExpressionBuilder firstName;

  final StringSqlExpressionBuilder lastName;

  final NumericSqlExpressionBuilder<double> salary;

  final DateTimeSqlExpressionBuilder createdAt;

  final DateTimeSqlExpressionBuilder updatedAt;
}
