import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_auth_twitter/angel_auth_twitter.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';

const Map<String, String> TWITTER_CONFIG = const {
  'callback': 'http://localhost:3000/auth/twitter/callback',
  'key': 'qlrBWXneoSYZKS2bT4TGHaNaV',
  'secret': 'n2oA0ZtR7TzYincpMYElRpyYovAQlhYizTkTm2x5QxjH6mLVyE'
};

main() async {
  var app = new Angel();

  var auth = new AngelAuth(jwtKey: 'AUTH_TWITTER_SECRET', allowCookie: false);
  await app.configure(auth);

  auth.serializer = (user) async => user.id_str;

  auth.deserializer = (id) async {
    // Of course, in a real app, you would fetch
    // user data, but not here.
    return {'id': id};
  };

  auth.strategies.add(new TwitterStrategy(config: TWITTER_CONFIG));

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
        ..write('Hello, user #${req.user["id"]}!')
        ..end();
    });

  await new DiagnosticsServer(app, new File('log.txt')).startServer(null, 3000);
}
