import 'package:angel_route/angel_route.dart';
import 'package:test/test.dart';

main() {
  final parent = new Router()..debug = true;
  final child = new Router()..debug = true;
  final a = child.get('a', ['c']);
  parent.use('child', child);
  parent.dumpTree();

  group('no params', () {
    test('resolve', () {
      expect(parent.resolve('child/a'), equals(a));
      expect(parent.resolve('a'), isNull);
    });
  });
}
