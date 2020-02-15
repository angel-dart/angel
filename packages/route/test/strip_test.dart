import 'package:angel_route/string_util.dart';
import 'package:test/test.dart';

main() {
  test('strip leading', () {
    var a = '///a';
    var b = stripStraySlashes(a);
    print('$a => $b');
    expect(b, 'a');
  });

  test('strip trailing', () {
    var a = 'a///';
    var b = stripStraySlashes(a);
    print('$a => $b');
    expect(b, 'a');
  });

  test('strip both', () {
    var a = '///a///';
    var b = stripStraySlashes(a);
    print('$a => $b');
    expect(b, 'a');
  });

  test('intermediate slashes preserved', () {
    var a = '///a///b//';
    var b = stripStraySlashes(a);
    print('$a => $b');
    expect(b, 'a///b');
  });

  test('only if starts with', () {
    var a = 'd///a///b//';
    var b = stripStraySlashes(a);
    print('$a => $b');
    expect(b, 'd///a///b');
  });

  test('only if ends with', () {
    var a = '///a///b//c';
    var b = stripStraySlashes(a);
    print('$a => $b');
    expect(b, 'a///b//c');
  });
}
