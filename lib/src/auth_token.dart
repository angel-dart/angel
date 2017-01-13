import 'dart:collection';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';

class AuthToken {
  final SplayTreeMap<String, String> _header =
      new SplayTreeMap.from({"alg": "HS256", "typ": "JWT"});

  String ipAddress;
  DateTime issuedAt;
  num lifeSpan;
  var userId;
  Map<String, dynamic> payload = {};

  AuthToken(
      {this.ipAddress,
      this.lifeSpan: -1,
      this.userId,
      DateTime issuedAt,
      Map<String, dynamic> payload: const {}}) {
    this.issuedAt = issuedAt ?? new DateTime.now();
    this.payload.addAll(payload ?? {});
  }

  factory AuthToken.fromJson(String json) =>
      new AuthToken.fromMap(JSON.decode(json));

  factory AuthToken.fromMap(Map data) {
    return new AuthToken(
        ipAddress: data["aud"],
        lifeSpan: data["exp"],
        issuedAt: DateTime.parse(data["iat"]),
        userId: data["sub"],
        payload: data["pld"] ?? {});
  }

  factory AuthToken.validate(String jwt, Hmac hmac) {
    var split = jwt.split(".");

    if (split.length != 3)
      throw new AngelHttpException.notAuthenticated(message: "Invalid JWT.");

    // var headerString = new String.fromCharCodes(BASE64URL.decode(split[0]));
    var payloadString = new String.fromCharCodes(BASE64URL.decode(split[1]));
    var data = split[0] + "." + split[1];
    var signature = BASE64URL.encode(hmac.convert(data.codeUnits).bytes);

    if (signature != split[2])
      throw new AngelHttpException.notAuthenticated(
          message: "JWT payload does not match hashed version.");

    return new AuthToken.fromMap(JSON.decode(payloadString));
  }

  String serialize(Hmac hmac) {
    var headerString = BASE64URL.encode(JSON.encode(_header).codeUnits);
    var payloadString = BASE64URL.encode(JSON.encode(toJson()).codeUnits);
    var data = headerString + "." + payloadString;
    var signature = hmac.convert(data.codeUnits).bytes;
    return data + "." + BASE64URL.encode(signature);
  }

  Map toJson() {
    return _splayify({
      "iss": "angel_auth",
      "aud": ipAddress,
      "exp": lifeSpan,
      "iat": issuedAt.toIso8601String(),
      "sub": userId,
      "pld": _splayify(payload)
    });
  }
}

SplayTreeMap _splayify(Map map) {
  var data = {};
  map.forEach((k, v) {
    data[k] = _splay(v);
  });
  return new SplayTreeMap.from(data);
}

_splay(value) {
  if (value is Iterable) {
    return value.map(_splay).toList();
  } else if (value is Map)
    return _splayify(value);
  else
    return value;
}
