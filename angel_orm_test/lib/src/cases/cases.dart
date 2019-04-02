import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'standalone.dart';

void ormTests(QueryExecutor Function() executor) {
  group('standalone', standaloneTests(executor));
}
