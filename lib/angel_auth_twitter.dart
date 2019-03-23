import 'dart:async';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:oauth/oauth.dart' as oauth;
import 'package:path/path.dart' as p;
import 'package:twitter/twitter.dart';

/// Authenticates users by connecting to Twitter's API.
class TwitterStrategy<User> extends AuthStrategy<User> {
  /// The options defining how to connect to the third-party.
  final ExternalAuthOptions options;

  /// A callback that uses Twitter to authenticate a [User].
  ///
  /// As always, return `null` if authentication fails.
  final FutureOr<User> Function(Twitter, RequestContext, ResponseContext)
      verifier;

  /// The root of Twitter's API. Defaults to `'https://api.twitter.com'`.
  final Uri baseUrl;

  oauth.Client _client;

  /// The underlying [oauth.Client] used to query Twitter.
  oauth.Client get client => _client;

  TwitterStrategy(this.options, this.verifier,
      {http.BaseClient client, Uri baseUrl})
      : this.baseUrl = baseUrl ?? Uri.parse('https://api.twitter.com') {
    var tokens = oauth.Tokens(
        consumerId: options.clientId, consumerKey: options.clientSecret);
    _client = oauth.Client(tokens, client: client);
  }

  /// Handle a response from Twitter.
  Future<Map<String, String>> handleUrlEncodedResponse(http.Response rs) async {
    var body = rs.body;

    if (rs.statusCode != 200) {
      throw new AngelHttpException.notAuthenticated(
          message: 'Twitter authentication error: $body');
    }

    return Uri.splitQueryString(body);
  }

  /// Get an access token.
  Future<Map<String, String>> getAccessToken(String token, String verifier) {
    return _client.post(
        baseUrl.replace(path: p.join(baseUrl.path, 'oauth/access_token')),
        body: {
          'oauth_token': token,
          'oauth_verifier': verifier
        }).then(handleUrlEncodedResponse);
    // var request = await createRequest("oauth/access_token",
    //     method: "POST", data: {"verifier": verifier}, accessToken: token);
  }

  /// Get a request token.
  Future<Map<String, String>> getRequestToken() {
    return _client.post(
        baseUrl.replace(path: p.join(baseUrl.path, 'oauth/request_token')),
        body: {
          "oauth_callback": options.redirectUri.toString()
        }).then(handleUrlEncodedResponse);
  }

  @override
  Future<User> authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {
    if (options != null) {
      return await authenticateCallback(req, res, options);
    } else {
      var result = await getRequestToken();
      var token = result['oauth_token'];
      var url = baseUrl.replace(
          path: p.join(baseUrl.path, 'oauth/authorize'),
          queryParameters: {'oauth_token': token});
      res.redirect(url);
      return null;
    }
  }

  Future<User> authenticateCallback(
      RequestContext req, ResponseContext res, AngelAuthOptions options) async {
    // TODO: Handle errors
    var token = req.queryParameters['oauth_token'] as String;
    var verifier = req.queryParameters['oauth_verifier'] as String;
    var loginData = await getAccessToken(token, verifier);
    var twitter = Twitter(this.options.clientId, this.options.clientSecret,
        loginData['oauth_token'], loginData['oauth_token_secret']);
    return await this.verifier(twitter, req, res);
  }
}
