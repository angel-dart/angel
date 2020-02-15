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

/// Represents the response for an OAuth2 `device_code` request.
class DeviceCodeResponse {
  /// REQUIRED. The device verification code.
  final String deviceCode;

  /// REQUIRED. The end-user verification code.
  final String userCode;

  /// REQUIRED. The end-user verification URI on the authorization
  /// server. The URI should be short and easy to remember as end users
  /// will be asked to manually type it into their user-agent.
  final Uri verificationUri;

  /// OPTIONAL.  A verification URI that includes the [userCode] (or
  /// other information with the same function as the [userCode]),
  /// designed for non-textual transmission.
  final Uri verificationUriComplete;

  /// OPTIONAL.  The minimum amount of time in seconds that the client
  /// SHOULD wait between polling requests to the token endpoint.  If no
  /// value is provided, clients MUST use 5 as the default.
  final int interval;

  /// The lifetime, in *seconds* of the [deviceCode] and [userCode].
  final int expiresIn;

  const DeviceCodeResponse(
      this.deviceCode, this.userCode, this.verificationUri, this.expiresIn,
      {this.verificationUriComplete, this.interval});

  Map<String, dynamic> toJson() {
    var out = <String, dynamic>{
      'device_code': deviceCode,
      'user_code': userCode,
      'verification_uri': verificationUri.toString(),
    };

    if (verificationUriComplete != null) {
      out['verification_uri_complete'] = verificationUriComplete.toString();
    }

    if (interval != null) out['interval'] = interval;
    if (expiresIn != null) out['expires_in'] = expiresIn;

    return out;
  }
}
