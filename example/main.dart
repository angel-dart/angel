import 'dart:convert';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_auth_oauth2/angel_auth_oauth2.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';

var authorizationEndpoint =
    Uri.parse('http://github.com/login/oauth/authorize');

var tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');

var options = ExternalAuthOptions(
  clientId: '6caeaf5d4c04936ec34f',
  clientSecret: '178360518cf9de4802e2346a4b6ebec525dc4427',
  redirectUri: Uri.parse('http://localhost:3000/auth/github/callback'),
);

/// Github doesn't properly follow the OAuth2 spec, so here's logic to parse their response.
Map<String, dynamic> parseParamsFromGithub(MediaType contentType, String body) {
  if (contentType.type == 'application') {
    if (contentType.subtype == 'x-www-form-urlencoded')
      return Uri.splitQueryString(body);
    else if (contentType.subtype == 'json')
      return (json.decode(body) as Map).cast<String, String>();
  }

  throw FormatException(
      'Invalid content-type $contentType; expected application/x-www-form-urlencoded or application/json.');
}

main() async {
  // Create the server instance.
  var app = Angel();
  var http = AngelHttp(app);
  app.logger = Logger('angel')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  // Create a service that stores user data.
  var userService = app.use('/users', MapService()).inner;
  var mappedUserService = userService.map(User.parse, User.serialize);

  // Set up the authenticator plugin.
  var auth =
      AngelAuth<User>(jwtKey: 'oauth2 example secret', allowCookie: false);
  auth.serializer = (user) async => user.id;
  auth.deserializer = (id) => mappedUserService.read(id.toString());
  app.fallback(auth.decodeJwt);

  /// Create an instance of the strategy class.
  auth.strategies['github'] = OAuth2Strategy(
    options,
    authorizationEndpoint,
    tokenEndpoint,

    // This function is called when the user ACCEPTS the request to sign in with Github.
    (client, req, res) async {
      var response = await client.get('https://api.github.com/user');
      var ghUser = json.decode(response.body);
      var id = ghUser['id'] as int;

      var matchingUsers = await mappedUserService.index({
        'query': {'github_id': id}
      });

      if (matchingUsers.isNotEmpty) {
        // Return the corresponding user, if it exists.
        return matchingUsers.first;
      } else {
        // Otherwise,create a user
        return await mappedUserService.create(User(githubId: id));
      }
    },

    // This function is called when an error occurs, or the user REJECTS the request.
    (e, req, res) async {
      res.write('Ooops: $e');
      await res.close();
    },

    // We have to pass this parser function when working with Github.
    getParameters: parseParamsFromGithub,
  );

  // Mount some routes
  app.get('/auth/github', auth.authenticate('github'));
  app.get(
      '/auth/github/callback',
      auth.authenticate('github',
          AngelAuthOptions(callback: (req, res, jwt) async {
        // In real-life, you might include a pop-up callback script.
        //
        // Use `confirmPopupAuthentication`, which is bundled with
        // `package:angel_auth`.
        var user = req.container.make<User>();
        res.write('Your user info: ${user.toJson()}\n\n');
        res.write('Your JWT: $jwt');
        await res.close();
      })));

  // Start listening.
  await http.startServer('127.0.0.1', 3000);
  print('Listening on ${http.uri}');
  print('View user listing: ${http.uri}/users');
  print('Sign in via Github: ${http.uri}/auth/github');
}

class User extends Model {
  @override
  String id;

  int githubId;

  User({this.id, this.githubId});

  static User parse(Map map) =>
      User(id: map['id'] as String, githubId: map['github_id'] as int);

  static Map<String, dynamic> serialize(User user) => user.toJson();

  Map<String, dynamic> toJson() => {'id': id, 'github_id': githubId};
}
