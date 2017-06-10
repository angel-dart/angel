library angel.routes.controllers.auth;

import 'package:angel_common/angel_common.dart';
import '../../services/user.dart';

/// Configures the application to authenticate users securely.
/// See the documentation for controllers:
///
/// https://github.com/angel-dart/angel/wiki/Controllers
@Expose('/auth')
class AuthController extends Controller {
  /// Controls application authentication.
  ///
  /// See the documentation:
  /// * https://medium.com/the-angel-framework/logging-users-in-to-angel-applications-ccf32aba0dac
  /// * https://github.com/angel-dart/auth
  AngelAuth auth;

  /// Clients will see the result of `deserializer`, so let's pretend to be a client.
  ///
  /// Our User service is already wired to remove sensitive data from serialized JSON.
  deserializer(String id) async =>
      app.service('api/users').read(id, {'provider': Providers.REST});

  serializer(User user) async => user.id;

  /// Attempts to log a user in.
  LocalAuthVerifier localVerifier(Service userService) {
    return (String username, String password) async {
      Iterable<User> users = await userService.index({
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
