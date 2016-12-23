import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:crypto/crypto.dart';
import 'package:random_string/random_string.dart' as rs;

const String _ENDPOINT = "https://api.twitter.com";

class TwitterStrategy extends AuthStrategy {
  HttpClient _client = new HttpClient();
  final Map<String, dynamic> config;

  @override
  String get name => 'twitter';

  TwitterStrategy({this.config: const {}});

  String _createSignature(
      String method, String uriString, Map<String, String> params,
      {String tokenSecret: ""}) {
    // Not only do we need to sort the parameters, but we need to URI-encode them as well.
    var encoded = new SplayTreeMap();
    for (String key in params.keys) {
      encoded[Uri.encodeComponent(key)] = Uri.encodeComponent(params[key]);
    }

    String collectedParams =
        encoded.keys.map((key) => "$key=${encoded[key]}").join("&");

    String baseString =
        "$method&${Uri.encodeComponent(uriString)}&${Uri.encodeComponent(
        collectedParams)}";

    String signingKey = "${Uri.encodeComponent(
        config['secret'])}&$tokenSecret";

    // After you create a base string and signing key, we need to hash this via HMAC-SHA1
    var hmac = new Hmac(sha1, signingKey.codeUnits);

    // The returned signature should be the resulting hash, Base64-encoded
    return BASE64.encode(hmac.convert(baseString.codeUnits).bytes);
  }

  Future<HttpClientRequest> _prepRequest(String path,
      {String method: "GET",
      Map data: const {},
      String accessToken,
      String tokenSecret: ""}) async {
    Map headers = new Map.from(data);
    headers["oauth_version"] = "1.0";
    headers["oauth_consumer_key"] = config['key'];

    // The implementation of _randomString doesn't matter - just generate a 32-char
    // alphanumeric string.
    headers["oauth_nonce"] = rs.randomAlphaNumeric(32);
    headers["oauth_signature_method"] = "HMAC-SHA1";
    headers["oauth_timestamp"] =
        (new DateTime.now().millisecondsSinceEpoch / 1000).round().toString();

    if (accessToken != null) {
      headers["oauth_token"] = accessToken;
    }

    var request = await _client.openUrl(method, Uri.parse("$_ENDPOINT$path"));

    headers['oauth_signature'] = _createSignature(method,
        request.uri.toString().replaceAll("?${request.uri.query}", ""), headers,
        tokenSecret: tokenSecret);

    var oauthString = headers.keys
        .map((name) => '$name="${Uri.encodeComponent(headers[name])}"')
        .join(", ");

    return request
      ..headers.set(HttpHeaders.AUTHORIZATION, "OAuth $oauthString");
  }

  _mapifyRequest(HttpClientRequest request) async {
    var rs = await request.close();
    var body = await rs.transform(UTF8.decoder).join();

    if (rs.statusCode != HttpStatus.OK) {
      throw new AngelHttpException.NotAuthenticated(
          message: 'Twitter authentication error: $body');
    }

    var pairs = body.split('&');
    var data = {};

    for (var pair in pairs) {
      var index = pair.indexOf('=');

      if (index > -1) {
        var key = pair.substring(0, index);
        var value = Uri.decodeFull(pair.substring(index + 1));
        data[key] = value;
      }
    }

    return data;
  }

  Future<Map<String, String>> createAccessToken(
      String token, String verifier) async {
    var request = await _prepRequest("/oauth/access_token",
        method: "POST", data: {"verifier": verifier}, accessToken: token);

    request.headers.contentType =
        ContentType.parse("application/x-www-form-urlencoded");
    request.writeln("oauth_verifier=$verifier");

    return _mapifyRequest(request);
  }

  Future<Map<String, String>> createRequestToken() async {
    var request = await _prepRequest("/oauth/request_token",
        method: "POST", data: {"oauth_callback": config['callback']});

    // _mapifyRequest is a function that sends a request and parses its URL-encoded
    // response into a Map. This detail is not important.
    return await _mapifyRequest(request);
  }

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async => true;
  @override
  authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {
    if (options != null) {
      return await authenticateCallback(req, res, options);
    } else {
      var result = await createRequestToken();
      String token = result['oauth_token'];
      res.redirect("$_ENDPOINT/oauth/authenticate?oauth_token=$token");
      return false;
    }
  }

  Future authenticateCallback(
      RequestContext req, ResponseContext res, AngelAuthOptions options) async {
    var token = req.query['oauth_token'];
    var verifier = req.query['oauth_verifier'];
    var loginData = await createAccessToken(token, verifier);

    var oauthToken = loginData['oauth_token'];
    var oauthTokenSecret = loginData['oauth_token_secret'];

    var request = await _prepRequest('/1.1/account/verify_credentials.json',
        accessToken: oauthToken, tokenSecret: oauthTokenSecret);
    var rs = await request.close();
    var body = await rs.transform(UTF8.decoder).join();
    return new Extensible()..properties.addAll(JSON.decode(body));
  }
}
