import 'dart:convert';
import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/common.dart';
import 'package:angel_auth_oauth2/angel_auth_oauth2.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

const Map<String, String> OAUTH2_CONFIG = const {
  'callback': '<callback-url>',
  'key': '<client-id>',
  'secret': '<my-secret>',
  'authorizationEndpoint': '<auth-url>',
  'tokenEndpoint': '<token-url>'
};

main() async {
  var app = new Angel()..use('/users', new TypedService<User>(new MapService()));

  var auth = new AngelAuth(jwtKey: 'oauth2 example secret', allowCookie: false);
  auth.deserializer =
      (String idStr) => app.service('users').read(int.parse(idStr));
  auth.serializer = (User user) async => user.id;

  auth.strategies.add(new OAuth2Strategy('example_site', OAUTH2_CONFIG,
      (oauth2.Client client) async {
    var response = await client.get('/link/to/user/profile');
    return JSON.decode(response.body);
  }));

  app.get('/auth/example_site', auth.authenticate('example_site'));
  app.get(
      '/auth/example_site/callback',
      auth.authenticate('example_site',
          new AngelAuthOptions(callback: (req, res, jwt) async {
        // In real-life, you might include a pop-up callback script
        res.write('Your JWT: $jwt');
      })));

  await app.configure(auth);
  await app.configure(logRequests(new File('log.txt')));
  await app.configure(profileRequests());

  var server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
  print('Listening on http://${server.address.address}:${server.port}');
}

class User extends Model {
  String example_siteId;

  User({String id, this.example_siteId}) {
    this.id = id;
  }
}
