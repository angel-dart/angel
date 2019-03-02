import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:random_string/random_string.dart' as rs;
import 'package:twitter/twitter.dart';

class TwitterStrategy<User> extends AuthStrategy<User> {
  /// The options defining how to connect to the third-party.
  final ExternalAuthOptions options;

  /// The underlying [BaseClient] used to query Twitter.
  final http.BaseClient httpClient;

  /// A callback that uses Twitter to authenticate a [User].
  ///
  /// As always, return `null` if authentication fails.
  final FutureOr<User> Function(Twitter, RequestContext, ResponseContext)
      verifier;

  /// The root of Twitter's API. Defaults to `'https://api.twitter.com'`.
  final Uri baseUrl;

  TwitterStrategy(this.options, this.verifier,
      {http.BaseClient client, Uri baseUrl})
      : this.baseUrl = baseUrl ?? Uri.parse('https://api.twitter.com'),
        this.httpClient = client ?? http.Client() as http.BaseClient;

  String _createSignature(
      String method, String uriString, Map<String, String> params,
      {@required String tokenSecret}) {
    // Not only do we need to sort the parameters, but we need to URI-encode them as well.
    var encoded = new SplayTreeMap();
    for (String key in params.keys) {
      encoded[Uri.encodeComponent(key)] = Uri.encodeComponent(params[key]);
    }

    String collectedParams =
        encoded.keys.map((key) => "$key=${encoded[key]}").join("&");

    String baseString =
        "$method&${Uri.encodeComponent(uriString)}&${Uri.encodeComponent(collectedParams)}";

    String signingKey =
        "${Uri.encodeComponent(options.clientSecret)}&$tokenSecret";

    // After you create a base string and signing key, we need to hash this via HMAC-SHA1
    var hmac = new Hmac(sha1, signingKey.codeUnits);

    // The returned signature should be the resulting hash, Base64-encoded
    return base64.encode(hmac.convert(baseString.codeUnits).bytes);
  }

  Future<http.Request> _prepRequest(String path,
      {String method = "GET",
      Map<String, String> data = const {},
      String accessToken,
      String tokenSecret = ''}) async {
    var headers = new Map<String, String>.from(data);
    headers["oauth_version"] = "1.0";
    headers["oauth_consumer_key"] = options.clientId;

    // The implementation of _randomString doesn't matter - just generate a 32-char
    // alphanumeric string.
    headers["oauth_nonce"] = rs.randomAlphaNumeric(32);
    headers["oauth_signature_method"] = "HMAC-SHA1";
    headers["oauth_timestamp"] =
        (new DateTime.now().millisecondsSinceEpoch / 1000).round().toString();

    if (accessToken != null) {
      headers["oauth_token"] = accessToken;
    }

    var request = http.Request(method, baseUrl.replace(path: path));

    headers['oauth_signature'] = _createSignature(
        method, request.url.toString(), headers,
        tokenSecret: tokenSecret);

    var oauthString = headers.keys
        .map((name) => '$name="${Uri.encodeComponent(headers[name])}"')
        .join(", ");

    return request
      ..headers.addAll(headers)
      ..headers['authorization'] = "OAuth $oauthString";
  }

  Future<Map<String, String>> _parseUrlEncoded(http.BaseRequest rq) async {
    var response = await httpClient.send(rq);
    var rs = await http.Response.fromStream(response);
    var body = rs.body;

    if (rs.statusCode != 200) {
      throw new AngelHttpException.notAuthenticated(
          message: 'Twitter authentication error: $body');
    }

    return Uri.splitQueryString(body);
  }

  Future<Map<String, String>> _createAccessToken(
      String token, String verifier) async {
    var request = await _prepRequest("oauth/access_token",
        method: "POST", data: {"verifier": verifier}, accessToken: token);
    request.bodyFields = {'oauth_verifier': verifier};
    return _parseUrlEncoded(request);
  }

  Future<Map<String, String>> createRequestToken() async {
    var request = await _prepRequest("oauth/request_token",
        method: "POST",
        data: {"oauth_callback": options.redirectUri.toString()});

    // _mapifyRequest is a function that sends a request and parses its URL-encoded
    // response into a Map. This detail is not important.
    return await _parseUrlEncoded(request);
  }

  @override
  Future<User> authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {
    if (options != null) {
      return await authenticateCallback(req, res, options);
    } else {
      var result = await createRequestToken();
      var token = result['oauth_token'];
      var url = baseUrl.replace(
          path: p.join(baseUrl.path, 'oauth/authenticate'),
          queryParameters: {'oauth_token': token});
      res.redirect(url);
      return null;
    }
  }

  Future<User> authenticateCallback(
      RequestContext req, ResponseContext res, AngelAuthOptions options) async {
    // TODO: Handle errors
    print('Query: ${req.queryParameters}');
    var token = req.queryParameters['oauth_token'] as String;
    var verifier = req.queryParameters['oauth_verifier'] as String;
    var loginData = await _createAccessToken(token, verifier);
    var twitter = Twitter(this.options.clientId, this.options.clientSecret,
        loginData['oauth_token'], loginData['oauth_token_secret']);
    return await this.verifier(twitter, req, res);
  }
}
