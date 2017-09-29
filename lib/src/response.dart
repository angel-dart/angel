class AuthorizationCodeResponse {
  final String accessToken;
  final String refreshToken;

  const AuthorizationCodeResponse(this.accessToken, {this.refreshToken});

  Map<String, String> toJson() {
    var map = <String, String> {'access_token': accessToken};
    if (refreshToken?.isNotEmpty == true) map['refresh_token'] = refreshToken;
    return map;
  }
}