/// Represents an OAuth2 authorization token.
class AuthorizationTokenResponse {
  /// The string that third parties should use to act on behalf of the user in question.
  final String accessToken;

  /// An optional key that can be used to refresh the [accessToken] past its expiration.
  final String refreshToken;

  /// An optional, but recommended integer that signifies the time left until the [accessToken] expires.
  final int expiresIn;

  /// Optional, if identical to the scope requested by the client; otherwise, required.
  final Iterable<String> scope;

  const AuthorizationTokenResponse(this.accessToken,
      {this.refreshToken, this.expiresIn, this.scope});

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{'access_token': accessToken};
    if (refreshToken?.isNotEmpty == true) map['refresh_token'] = refreshToken;
    if (expiresIn != null) map['expires_in'] = expiresIn;
    if (scope != null) map['scope'] = scope.toList();
    return map;
  }
}
