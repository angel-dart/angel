import 'dart:collection';
import 'package:angel_framework/angel_framework.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Calls [BASE64URL], but also works for strings with lengths
/// that are *not* multiples of 4.
String decodeBase64(String str) {
  var output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw 'Illegal base64url string!"';
  }

  return utf8.decode(base64Url.decode(output));
}

class AuthToken {
  final SplayTreeMap<String, String> _header =
      SplayTreeMap.from({"alg": "HS256", "typ": "JWT"});

  String ipAddress;
  DateTime issuedAt;
  num lifeSpan;
  var userId;
  Map<String, dynamic> payload = {};

  AuthToken(
      {this.ipAddress,
      this.lifeSpan = -1,
      this.userId,
      DateTime issuedAt,
      Map payload = const {}}) {
    this.issuedAt = issuedAt ?? DateTime.now();
    this.payload.addAll(
        payload?.keys?.fold({}, (out, k) => out..[k.toString()] = payload[k]) ??
            {});
  }

  factory AuthToken.fromJson(String jsons) =>
      AuthToken.fromMap(json.decode(jsons) as Map);

  factory AuthToken.fromMap(Map data) {
    return AuthToken(
        ipAddress: data["aud"].toString(),
        lifeSpan: data["exp"] as num,
        issuedAt: DateTime.parse(data["iat"].toString()),
        userId: data["sub"],
        payload: data["pld"] as Map ?? {});
  }

  factory AuthToken.parse(String jwt) {
    var split = jwt.split(".");

    if (split.length != 3)
      throw AngelHttpException.notAuthenticated(message: "Invalid JWT.");

    var payloadString = decodeBase64(split[1]);
    return AuthToken.fromMap(json.decode(payloadString) as Map);
  }

  factory AuthToken.validate(String jwt, Hmac hmac) {
    var split = jwt.split(".");

    if (split.length != 3)
      throw AngelHttpException.notAuthenticated(message: "Invalid JWT.");

    // var headerString = decodeBase64(split[0]);
    var payloadString = decodeBase64(split[1]);
    var data = split[0] + "." + split[1];
    var signature = base64Url.encode(hmac.convert(data.codeUnits).bytes);

    if (signature != split[2])
      throw AngelHttpException.notAuthenticated(
          message: "JWT payload does not match hashed version.");

    return AuthToken.fromMap(json.decode(payloadString) as Map);
  }

  String serialize(Hmac hmac) {
    var headerString = base64Url.encode(json.encode(_header).codeUnits);
    var payloadString = base64Url.encode(json.encode(toJson()).codeUnits);
    var data = headerString + "." + payloadString;
    var signature = hmac.convert(data.codeUnits).bytes;
    return data + "." + base64Url.encode(signature);
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
  return SplayTreeMap.from(data);
}

_splay(value) {
  if (value is Iterable) {
    return value.map(_splay).toList();
  } else if (value is Map)
    return _splayify(value);
  else
    return value;
}
