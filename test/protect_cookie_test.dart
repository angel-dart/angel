import 'dart:io';

import 'package:angel_auth/angel_auth.dart';
import 'package:test/test.dart';

const Duration threeDays = const Duration(days: 3);

void main() {
  Cookie defaultCookie;
  var auth = AngelAuth(
    secureCookies: true,
    cookieDomain: 'SECURE',
    jwtLifeSpan: threeDays.inMilliseconds,
  );

  setUp(() => defaultCookie = Cookie('a', 'b'));

  test('sets maxAge', () {
    expect(auth.protectCookie(defaultCookie).maxAge, threeDays.inSeconds);
  });

  test('sets expires', () {
    var now = DateTime.now();
    var expiry = auth.protectCookie(defaultCookie).expires;
    var diff = expiry.difference(now);
    expect(diff.inSeconds, threeDays.inSeconds);
  });

  test('sets httpOnly', () {
    expect(auth.protectCookie(defaultCookie).httpOnly, true);
  });

  test('sets secure', () {
    expect(auth.protectCookie(defaultCookie).secure, true);
  });

  test('sets domain', () {
    expect(auth.protectCookie(defaultCookie).domain, 'SECURE');
  });

  test('preserves domain if present', () {
    expect(auth.protectCookie(defaultCookie..domain = 'foo').domain, 'foo');
  });
}
