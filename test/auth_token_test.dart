import "package:angel_auth/src/auth_token.dart";
import "package:crypto/crypto.dart";
import "package:test/test.dart";

main() async {
  final Hmac hmac = Hmac(sha256, "angel_auth".codeUnits);

  test("sample serialization", () {
    var token = AuthToken(ipAddress: "localhost", userId: "thosakwe");
    var jwt = token.serialize(hmac);
    print(jwt);

    var parsed = AuthToken.validate(jwt, hmac);
    print(parsed.toJson());
    expect(parsed.toJson()['aud'], equals(token.ipAddress));
    expect(parsed.toJson()['sub'], equals(token.userId));
  });

  test('custom payload', () {
    var token = AuthToken(ipAddress: "localhost", userId: "thosakwe", payload: {
      "foo": "bar",
      "baz": {
        "one": 1,
        "franken": ["stein"]
      }
    });
    var jwt = token.serialize(hmac);
    print(jwt);

    var parsed = AuthToken.validate(jwt, hmac);
    print(parsed.toJson());
    expect(parsed.toJson()['pld'], equals(token.payload));
  });
}
