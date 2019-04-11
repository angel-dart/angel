import 'dart:convert';
import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_auth_twitter/angel_auth_twitter.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:logging/logging.dart';

class _User {
  final String handle;

  _User(this.handle);

  Map<String, dynamic> toJson() => {'handle': handle};
}

main() async {
  var app = Angel();
  var http = AngelHttp(app);
  var auth = AngelAuth<_User>(
    jwtKey: 'AUTH_TWITTER_SECRET',
    allowCookie: false,
    serializer: (user) async => user.handle,
    deserializer: (screenName) async {
      // Of course, in a real app, you would fetch
      // user data, but not here.
      return _User(screenName.toString());
    },
  );

  auth.strategies['twitter'] = TwitterStrategy(
    ExternalAuthOptions(
      clientId: Platform.environment['TWITTER_CLIENT_ID'] ??
          'qlrBWXneoSYZKS2bT4TGHaNaV',
      clientSecret: Platform.environment['TWITTER_CLIENT_SECRET'] ??
          'n2oA0ZtR7TzYincpMYElRpyYovAQlhYizTkTm2x5QxjH6mLVyE',
      redirectUri: Platform.environment['TWITTER_REDIRECT_URI'] ??
          'http://localhost:3000/auth/twitter/callback',
    ),
    (twit, req, res) async {
      var response = await twit.twitterClient
          .get('https://api.twitter.com/1.1/account/verify_credentials.json');
      var userData = json.decode(response.body) as Map;
      return _User(userData['screen_name'] as String);
    },
    (e, req, res) async {
      // When an error occurs, i.e. the user declines to approve the application.
      if (e.isDenial) {
        res.write("Why'd you say no???");
      } else {
        res.write("oops: ${e.message}");
      }
    },
  );

  app
    ..fallback(auth.decodeJwt)
    ..get('/', auth.authenticate('twitter'));

  app
    ..get(
      '/auth/twitter/callback',
      auth.authenticate(
        'twitter',
        AngelAuthOptions(
          callback: (req, res, jwt) {
            return res.redirect('/home?token=$jwt');
          },
        ),
      ),
    );

  app.get(
    '/home',
    chain([
      requireAuthentication<_User>(),
      (req, res) {
        var user = req.container.make<_User>();
        res.write('Your Twitter handle is ${user.handle}');
        return false;
      },
    ]),
  );

  app.logger = Logger('angel_auth_twitter')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  await http.startServer('127.0.0.1', 3000);
  print('Listening at ${http.uri}');
}
