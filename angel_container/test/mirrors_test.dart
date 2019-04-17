import 'dart:async';
import 'package:angel_container/angel_container.dart';
import 'package:angel_container/mirrors.dart';
import 'package:test/test.dart';
import 'common.dart';

void main() {
  testReflector(const MirrorsReflector());

  test('futureOf', () {
    var r = MirrorsReflector();
    var fStr = r.reflectFutureOf(String);
    expect(fStr.reflectedType.toString(), 'Future<String>');
    // expect(fStr.reflectedType, Future<String>.value(null).runtimeType);
  });

  test('concrete future make', () async {
    var c = Container(MirrorsReflector());
    c.registerFactory<Future<String>>((_) async => 'hey');
    var fStr = c.reflector.reflectFutureOf(String);
    var s1 = await c.make(fStr.reflectedType);
    var s2 = await c.makeAsync(String);
    print([s1, s2]);
    expect(s1, s2);
  });
}
