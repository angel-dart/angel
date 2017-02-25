library angel.routes.controllers.auth;

import 'package:angel_common/angel_common.dart';
import '../../services/user.dart';

@Expose('/auth')
class AuthController extends Controller {
  AngelAuth auth;

  deserializer(String id) async => app.service('api/users').read(id);
  serializer(User user) async => user.id;

  /// Attempt to log a user in
  LocalAuthVerifier localVerifier(UserService userService) {
    return (String username, String password) async {
      List<User> users = await userService.index({'query':{'username': username}});

      if (users.isNotEmpty) {
        var hash = hashPassword(password);
        return users.firstWhere((user) => user.password == hash,
            orElse: () => null);
      }
    };
  }

  @override
  call(Angel app) async {
    // Wire up local authentication, connected to our User service
    auth = new AngelAuth(jwtKey: app.jwt_secret)
      ..serializer = serializer
      ..deserializer = deserializer
      ..strategies.add(
          new LocalAuthStrategy(localVerifier(app.container.make(UserService))));

    await super.call(app);
    await app.configure(auth);
  }

  @Expose('/local', method: 'POST')
  login() => auth.authenticate('local');

  @Expose('/register', method: 'POST')
  register(RequestContext req, UserService userService) async {
    // And your registration logic...
  }
}
