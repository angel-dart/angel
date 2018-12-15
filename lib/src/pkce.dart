import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'exception.dart';

/// A class that facilitates verification of challenges for
/// [Proof Key for Code Exchange](https://oauth.net/2/pkce/).
class Pkce {
  /// A [String] defining how to handle the [codeChallenge].
  final String codeChallengeMethod;

  /// The proof key that is used to secure public clients.
  final String codeChallenge;

  Pkce(this.codeChallengeMethod, this.codeChallenge) {
    assert(codeChallengeMethod == 'plain' || codeChallengeMethod == 's256',
        "The `code_challenge_method` parameter must be either 'plain' or 's256'.");
  }

  /// Attempts to parse a [codeChallenge] and [codeChallengeMethod] from a [Map].
  factory Pkce.fromJson(Map data, {String state, Uri uri}) {
    var codeChallenge = data['code_challenge']?.toString();
    var codeChallengeMethod =
        data['code_challenge_method']?.toString() ?? 'plain';

    if (codeChallengeMethod != 'plain' && codeChallengeMethod != 's256') {
      throw new AuthorizationException(new ErrorResponse(
          ErrorResponse.invalidRequest,
          "The `code_challenge_method` parameter must be either 'plain' or 's256'.",
          state,
          uri: uri));
    } else if (codeChallenge?.isNotEmpty != true) {
      throw new AuthorizationException(new ErrorResponse(
          ErrorResponse.invalidRequest,
          'Missing `code_challenge` parameter.',
          state,
          uri: uri));
    }

    return new Pkce(codeChallengeMethod, codeChallenge);
  }

  /// Returns [true] if the [codeChallengeMethod] is `plain`.
  bool get isPlain => codeChallengeMethod == 'plain';

  /// Returns [true] if the [codeChallengeMethod] is `s256`.
  bool get isS256 => codeChallengeMethod == 's256';

  /// Determines if a given [codeVerifier] is valid.
  void validate(String codeVerifier, {String state, Uri uri}) {
    String foreignChallenge;

    if (isS256) {
      foreignChallenge =
          base64Url.encode(sha256.convert(ascii.encode(codeChallenge)).bytes);
    } else {
      foreignChallenge = codeChallenge;
    }

    if (foreignChallenge != codeChallenge) {
      throw new AuthorizationException(
        new ErrorResponse(ErrorResponse.invalidGrant,
            "The given `code_verifier` parameter is invalid.", state,
            uri: uri),
      );
    }
  }

  /// Creates a JSON-serializable representation of this instance.
  Map<String, dynamic> toJson() {
    return {
      'code_challenge': codeChallenge,
      'code_challenge_method': codeChallengeMethod
    };
  }
}
