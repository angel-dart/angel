import 'dart:async';
import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm/src/query.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'main.g.dart';

main() async {
  var query = new EmployeeQuery()
    ..where.firstName.equals('Rich')
    ..where.lastName.equals('Person')
    ..orWhere((w) => w.salary.greaterThanOrEqualTo(75000))
    ..join('companies', 'company_id', 'id');

  var richPerson = await query.getOne(new _FakeExecutor());
  print(richPerson.toJson());
}

class _FakeExecutor extends QueryExecutor {
  const _FakeExecutor();

  @override
  Future<List<List>> query(
      String tableName, String query, Map<String, dynamic> substitutionValues,
      [returningFields]) async {
    var now = new DateTime.now();
    print(
        '_FakeExecutor received query: $query and values: $substitutionValues');
    return [
      [1, 'Rich', 'Person', 100000.0, now, now]
    ];
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function() f) {
    throw new UnsupportedError('Transactions are not supported.');
  }
}

@orm
@serializable
abstract class _Employee extends Model {
  String get firstName;

  String get lastName;

  @Column(indexType: IndexType.unique)
  String uniqueId;

  double get salary;
}
