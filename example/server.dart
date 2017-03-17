import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_auth_twitter/angel_auth_twitter.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:twit/twit.dart';

const Map<String, String> TWITTER_CONFIG = const {
  'callback': 'http://localhost:3000/auth/twitter/callback',
  'key': 'qlrBWXneoSYZKS2bT4TGHaNaV',
  'secret': 'n2oA0ZtR7TzYincpMYElRpyYovAQlhYizTkTm2x5QxjH6mLVyE'
};

verifier(TwitBase twit) async {
  // Maybe fetch user credentials:
  return await twit.get('/account/verify_credentials.json');
}

main() async {
  var app = new Angel();

  var auth = new AngelAuth(jwtKey: 'AUTH_TWITTER_SECRET', allowCookie: false);
  await app.configure(auth);

  auth.serializer = (user) async => user['screen_name'];

  auth.deserializer = (screenName) async {
    // Of course, in a real app, you would fetch
    // user data, but not here.
    return {'handle': '@$screenName'};
  };

  auth.strategies.add(new TwitterStrategy(verifier, config: TWITTER_CONFIG));

  app
    ..get('/', auth.authenticate('twitter'))
    ..get(
        '/auth/twitter/callback',
        auth.authenticate('twitter',
            new AngelAuthOptions(callback: (req, res, jwt) {
          return res.redirect('/home?token=$jwt');
        })))
    ..chain('auth').get('/home', (req, res) {
      res
        ..write('Your Twitter handle is ${req.user["handle"]}.')
        ..end();
    });

  await app.configure(logRequests(new File('log.txt')));
  var server = await app.startServer(null, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
