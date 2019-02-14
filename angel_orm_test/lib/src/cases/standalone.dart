import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm_test/angel_orm_test.dart';
import 'package:test/test.dart';

void Function() standaloneTests(QueryExecutor Function() executorFn) {
  return () {
    test('insert one', () async {
      var executor = executorFn();
      var query = TodoQuery();
      query.values
        ..isComplete = false
        ..text = 'Clean your dirty room';
      var todo = await query.insert(executor);
      print(todo.toJson());
    });
  };
}
