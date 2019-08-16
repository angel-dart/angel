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
  ///
  /// If an [onInvalidCookie] callback is passed, then it will
  /// be invoked for each unsigned or improperly-signed cookie.
  List<Cookie> readCookies(RequestContext req,
      {void Function(Cookie) onInvalidCookie}) {
    return req.cookies.fold([], (out, cookie) {
      var data = getCookiePayloadAndSignature(cookie.value);
      if (data == null || (data[1] != computeCookieSignature(data[0]))) {
        if (onInvalidCookie != null) {
          onInvalidCookie(cookie);
        }
        return out;
      } else {
        return out..add(cookieWithNewValue(cookie, data[0]));
      }
    });
  }

  /// Determines whether a cookie is properly signed,
  /// if it is signed at all.
  ///
  /// If there is no signature, returns `false`.
  /// If the provided signature does not match the payload
  /// provided, returns `false`.
  /// Otherwise, returns true.
  bool verify(Cookie cookie) {
    var data = getCookiePayloadAndSignature(cookie.value);
    return (data != null && (data[1] == computeCookieSignature(data[0])));
  }

  /// Gets the payload and signature of a given [cookie], WITHOUT
  /// verifying its integrity.
  ///
  /// Returns `null` if no payload can be found.
  /// Otherwise, returns a list with a length of 2, where
  /// the item at index `0` is the payload, and the item at
  /// index `1` is the signature.
  List<String> getCookiePayloadAndSignature(String cookieValue) {
    var dot = cookieValue.indexOf('.');
    if (dot <= 0) {
      return null;
    } else if (dot >= cookieValue.length - 1) {
      return null;
    } else {
      var payload = cookieValue.substring(0, dot);
      var sig = cookieValue.substring(dot + 1);
      return [payload, sig];
    }
  }

  /// Signs a single [cookie], and adds it to an outgoing
  /// [res]ponse. The input [cookie] is not modified.
  ///
  /// See [createSignedCookie].
  void writeCookie(ResponseContext res, Cookie cookie) {
    res.cookies.add(createSignedCookie(cookie));
  }

  /// Signs a set of [cookies], and adds them to an outgoing
  /// [res]ponse. The input [cookies] are not modified.
  ///
  /// See [createSignedCookie].
  void writeCookies(ResponseContext res, Iterable<Cookie> cookies) {
    cookies.forEach((c) => writeCookie(res, c));
  }

  /// Returns a new cookie, replacing the value of an input
  /// [cookie] with one that is signed with the [hmac].
  ///
  /// The new value is:
  /// `cookie.value + "." + base64Url(sig)`
  ///
  /// Where `sig` is the cookie's value, signed with the [hmac].
  Cookie createSignedCookie(Cookie cookie) {
    return cookieWithNewValue(
        cookie, cookie.value + '.' + computeCookieSignature(cookie.value));
  }

  /// Returns a new [Cookie] that is the same as the input
  /// [cookie], but with a [newValue].
  Cookie cookieWithNewValue(Cookie cookie, String newValue) {
    return Cookie(cookie.name, newValue)
      ..domain = cookie.domain
      ..expires = cookie.expires
      ..httpOnly = cookie.httpOnly
      ..maxAge = cookie.maxAge
      ..path = cookie.path
      ..secure = cookie.secure;
  }

  /// Computes the *signature* of a [cookieValue], either for
  /// signing an outgoing cookie, or verifying an incoming cookie.
  String computeCookieSignature(String cookieValue) {
    // base64Url(cookie) + "." + base64Url(sig)
    // var encodedCookie = base64Url.encode(cookieValue.codeUnits);
    var sigBytes = hmac.convert(cookieValue.codeUnits).bytes;
    return base64Url.encode(sigBytes);
    // var sig = base64Url.encode(sigBytes);
    // return encodedCookie + '.' + sig;
  }
}
