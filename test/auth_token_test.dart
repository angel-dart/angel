import "package:angel_auth/src/auth_token.dart";
import "package:crypto/crypto.dart";
import "package:test/test.dart";

main() async {
  final Hmac hmac = new Hmac(sha256, "angel_auth".codeUnits);

  test("sample serialization", () {
    var token = new AuthToken(ipAddress: "localhost", userId: "thosakwe");
    var jwt = token.serialize(hmac);
    print(jwt);

    var parsed = new AuthToken.validate(jwt, hmac);
    print(parsed.toJson());
  });
}