import 'package:angel_orm_test/angel_orm_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'common.dart';

void main() {
  Logger.root.onRecord.listen((rec) {
    print(rec);
    if (rec.error != null) print(rec.error);
    if (rec.stackTrace != null) print(rec.stackTrace);
  });

  group('postgresql', () {
    group('belongsTo',
        () => belongsToTests(my(['author', 'book']), close: closeMy));
    group(
        'edgeCase',
        () => edgeCaseTests(my(['unorthodox', 'weird_join', 'song', 'numba']),
            close: closeMy));
    group('enumAndNested',
        () => enumAndNestedTests(my(['has_car']), close: closeMy));
    group('hasMany', () => hasManyTests(my(['tree', 'fruit']), close: closeMy));
    group('hasMap', () => hasMapTests(my(['has_map']), close: closeMy));
    group('hasOne', () => hasOneTests(my(['leg', 'foot']), close: closeMy));
    group(
        'manyToMany',
        () =>
            manyToManyTests(my(['user', 'role', 'user_role']), close: closeMy));
    group('standalone', () => standaloneTests(my(['car']), close: closeMy));
  });
}
