import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';

/// A utility that signs, and verifies, cookies using an [Hmac].
///
/// It aims to mitigate so-called "cookie poisoning" attacks by
/// ensuring that clients cannot tamper with the cookies they have been
/// sent.
class CookieSigner {
  /// The [Hmac] used to sign and verify cookies.
  final Hmac hmac;

  /// Creates an [hmac] from an array of [keyBytes] and a
  /// [hash] (defaults to [sha256]).
  CookieSigner(List<int> keyBytes, {Hash hash})
      : hmac = Hmac(hash ?? sha256, keyBytes);

  CookieSigner.fromHmac(this.hmac);

  /// Creates an [hmac] from a string [key] and a
  /// [hash] (defaults to [sha256]).
  factory CookieSigner.fromStringKey(String key, {Hash hash}) {
    return CookieSigner(utf8.encode(key), hash: hash);
  }

  /// Returns a set of all the incoming cookies that had a
  /// valid signature attached. Any cookies without a
  /// signature, or with a signature that does not match the
  /// provided data, are not included in the output.
  Iterable<Cookie> readCookies(RequestContext req) {}

  /// Signs a set of [cookies], and adds them to an outgoing
  /// [res]ponse.
  ///
  /// See [signCookie].
  void writeCookies(ResponseContext res, Iterable<Cookie> cookies) {
    for (var cookie in cookies) {
      signCookie(cookie);
      res.cookies.add(cookie);
    }
  }

  /// Returns a new cookie, replacing the value of an input
  /// [cookie] with one that is signed with the [hmac].
  ///
  /// The signature is:
  /// `base64Url(cookie.value) + "." + base64Url(sig)`
  ///
  /// Where `sig` is the cookie's value, signed with the [hmac].
  Cookie signCookie(Cookie cookie) {
    return Cookie(cookie.name, computeCookieSignature(cookie.value))
      ..domain = cookie.domain
      ..expires = cookie.expires
      ..httpOnly = cookie.httpOnly
      ..maxAge = cookie.maxAge
      ..path = cookie.path
      ..secure = cookie.secure;
  }

  /// Computes the signature of a [cookieValue], either for
  /// signing an outgoing cookie, or verifying an incoming cookie.
  String computeCookieSignature(String cookieValue) {
    // base64Url(cookie) + "." + base64Url(sig)
    var encodedCookie = base64Url.encode(cookieValue.codeUnits);
    var sigBytes = hmac.convert(cookieValue.codeUnits).bytes;
    var sig = base64Url.encode(sigBytes);
    return encodedCookie + '.' + sig;
  }
}
