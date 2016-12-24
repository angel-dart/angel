library angel.routes.controllers.auth;

import 'package:angel_common/angel_common.dart';
import '../../services/user.dart';

@Expose('/api/auth')
class AuthController extends Controller {
  AngelAuth auth;

  deserializer(String id) async => app.service('api/users').read(id);
  serializer(User user) async => user.id;

  /// Attempt to log a user in
  verifier(UserService Users) {
    return (String username, String password) async {
      List<User> users = await Users.index({'username': username});

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
          new LocalAuthStrategy(verifier(app.container.make(UserService))));

    await super.call(app);
    await app.configure(auth);
  }

  @Expose('/login', method: 'POST')
  login(RequestContext req) async {
    // Include log-in logic here...
  }

  @Expose('/register', method: 'POST')
  register(RequestContext req, UserService Users) async {
    // And your registration logic...
  }
}
