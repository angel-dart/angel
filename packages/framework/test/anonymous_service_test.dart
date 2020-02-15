import 'package:angel_framework/angel_framework.dart';
import 'package:test/test.dart';

main() {
  test('custom methods', () async {
    var svc = AnonymousService<String, String>(
        index: ([p]) async => ['index'],
        read: (id, [p]) async => 'read',
        create: (data, [p]) async => 'create',
        modify: (id, data, [p]) async => 'modify',
        update: (id, data, [p]) async => 'update',
        remove: (id, [p]) async => 'remove');
    expect(await svc.index(), ['index']);
    expect(await svc.read(null), 'read');
    expect(await svc.create(null), 'create');
    expect(await svc.modify(null, null), 'modify');
    expect(await svc.update(null, null), 'update');
    expect(await svc.remove(null), 'remove');
  });

  test('defaults to throwing', () async {
    try {
      var svc = AnonymousService();
      await svc.read(1);
      throw 'Should have thrown 405!';
    } on AngelHttpException {
      // print('Ok!');
    }
    try {
      var svc = AnonymousService();
      await svc.modify(2, null);
      throw 'Should have thrown 405!';
    } on AngelHttpException {
      // print('Ok!');
    }
    try {
      var svc = AnonymousService();
      await svc.update(3, null);
      throw 'Should have thrown 405!';
    } on AngelHttpException {
      // print('Ok!');
    }
  });
}
