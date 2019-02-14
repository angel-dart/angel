import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'standalone.dart';

void Function() ormTests(QueryExecutor executor) {
  return () {
    group('standalone', standaloneTests(executor));
  };
}