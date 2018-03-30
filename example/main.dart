import 'dart:convert';
import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/common.dart';
import 'package:angel_auth_oauth2/angel_auth_oauth2.dart';
import 'package:logging/logging.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

final AngelAuthOAuth2Options oAuth2Config = new AngelAuthOAuth2Options(
    callback: 'http://localhost:3000/auth/github/callback',
    key: '6caeaf5d4c04936ec34f',
    secret: '178360518cf9de4802e2346a4b6ebec525dc4427',
    authorizationEndpoint: 'http://github.com/login/oauth/authorize',
    tokenEndpoint: 'https://github.com/login/oauth/access_token',
    getParameters: (contentType, body) {
      if (contentType.type == 'application') {
        if (contentType.subtype == 'x-www-form-urlencoded')
          return Uri.splitQueryString(body);
        else if (contentType.subtype == 'json') return JSON.decode(body);
      }

      throw new FormatException('Invalid content-type $contentType; expected application/x-www-form-urlencoded or application/json.');
    });

main() async {
  var app = new Angel();
  app.lazyParseBodies = true;
  app.use('/users', new MapService());

  var auth =
      new AngelAuth<User>(jwtKey: 'oauth2 example secret', allowCookie: false);

  auth.deserializer =
      (id) => app.service('users').read(id).then((u) => User.parse(u));

  auth.serializer = (User user) async => user.id;

  auth.strategies.add(
      new OAuth2Strategy('github', oAuth2Config, (oauth2.Client client) async {
    var response = await client.get('https://api.github.com/user');
    var ghUser = JSON.decode(response.body);
    var id = ghUser['id'];

    Iterable<Map> matchingUsers = await app.service('users').index({
      'query': {'githubId': id}
    });

    if (matchingUsers.isNotEmpty) {
      // Return the corresponding user, if it exists
      return User.parse(matchingUsers.firstWhere((u) => u['githubId'] == id));
    } else {
      // Otherwise,create a user
      return await app
          .service('users')
          .create({'githubId': id}).then((u) => User.parse(u));
    }
  }));

  app.get('/auth/github', auth.authenticate('github'));
  app.get(
      '/auth/github/callback',
      auth.authenticate('github',
          new AngelAuthOptions(callback: (req, res, jwt) async {
        // In real-life, you might include a pop-up callback script.
        //
        // Use `confirmPopupAuthentication`, which is bundled with
        // `package:angel_auth`.
        res.write('Your JWT: $jwt');
      })));

  await app.configure(auth.configureServer);

  app.logger = new Logger('angel')..onRecord.listen(print);

  var http = new AngelHttp(app);
  var server = await http.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening on $url');
  print('View user listing: $url/users');
  print('Sign in via Github: $url/auth/github');
}

class User extends Model {
  @override
  String id;
  int githubId;

  User({this.id, this.githubId});

  static User parse(Map map) =>
      new User(id: map['id'], githubId: map['github_id']);

  Map<String, dynamic> toJson() => {'id': id, 'github_id': githubId};
}
