library angel.routes.controllers.auth;

import 'package:angel_common/angel_common.dart';
import '../../services/user.dart';

@Expose('/auth')
class AuthController extends Controller {
  AngelAuth auth;

  /// Clients will see the result of `deserializer`, so let's pretend to be a client.
  ///
  /// Our User service is already wired to remove sensitive data from serialized JSON.
  deserializer(String id) async =>
      app.service('api/users').read(id, {'provider': Providers.REST});

  serializer(User user) async => user.id;

  /// Attempt to log a user in
  LocalAuthVerifier localVerifier(Service userService) {
    return (String username, String password) async {
      List<User> users = await userService.index({
        'query': {'username': username}
      });

      if (users.isNotEmpty) {
        return users.firstWhere((user) {
          var hash = hashPassword(password, user.salt, app.jwt_secret);
          return user.username == username && user.password == hash;
        }, orElse: () => null);
      }
    };
  }

  @override
  call(Angel app) async {
    // Wire up local authentication, connected to our User service
    auth = new AngelAuth(jwtKey: app.jwt_secret)
      ..serializer = serializer
      ..deserializer = deserializer
      ..strategies
          .add(new LocalAuthStrategy(localVerifier(app.service('api/users'))));

    await super.call(app);
    await app.configure(auth);
  }

  @Expose('/local', method: 'POST')
  login() => auth.authenticate('local');
}
