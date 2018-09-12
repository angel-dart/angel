import 'dart:async';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';

main() async {
  var app = new Angel();
  var auth = new AngelAuth<User>();

  auth.serializer = (user) => user.id;

  auth.deserializer = (id) => fetchAUserByIdSomehow(id);

  // Middleware to decode JWT's and inject a user object...
  app.fallback(auth.decodeJwt);

  auth.strategies['local'] = new LocalAuthStrategy((username, password) {
    // Retrieve a user somehow...
    // If authentication succeeds, return a User object.
    //
    // Otherwise, return `null`.
  });

  app.post('/auth/local', auth.authenticate('local'));

  var http = new AngelHttp(app);
  await http.startServer('127.0.0.1', 3000);

  print('Listening at http://127.0.0.1:3000');
}

class User {
  String id, username, password;
}

Future<User> fetchAUserByIdSomehow(id) async {
  // Fetch a user somehow...
}
