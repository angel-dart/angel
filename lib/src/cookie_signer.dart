import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';

class CookieSigner {
  final Hmac hmac;

  CookieSigner(List<int> keyBytes, {Hash hash})
      : hmac = Hmac(hash ?? sha256, keyBytes);

  CookieSigner.fromHmac(this.hmac);

  factory CookieSigner.fromStringKey(String key, {Hash hash}) {
    if (key.length != 32) {
      throw ArgumentError.value(key, 'key', 'must have a length of 32');
    }
    return CookieSigner(utf8.encode(key), hash: hash);
  }

  Iterable<Cookie> readCookies(RequestContext req) {}

  void writeCookies(ResponseContext res, Iterable<Cookie> cookies) {
    for (var cookie in cookies) {
      signCookie(cookie);
      res.cookies.add(cookie);
    }
  }

  void signCookie(Cookie cookie) {}
}
