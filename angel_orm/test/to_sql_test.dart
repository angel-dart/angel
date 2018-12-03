import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';

void main() {
  test('simple', () {
    expect(toSql('ABC _!'), "'ABC _!'");
  });

  test('ignores null byte', () {
    expect(toSql('a\x00bc'), "'abc'");
  });

  test('unicode', () {
    expect(toSql('東'), r"'\u6771'");
    expect(toSql('𐐀'), r"'\U00010400'");
  });
}
