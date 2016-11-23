library angel.routes.controllers.auth;

import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import '../../services/user.dart';

@Expose("/auth")
class AuthController extends Controller {
  final AngelAuth _auth = new AngelAuth();

  _deserializer(String id) async => app.service("api/users").read(id);
  _serializer(User user) async => user.id;

  /// Attempt to log a user in
  _verifier(UserService Users) {
    return (String username, String password) async {
      List<User> users = await Users.index({"username": username});

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
    _auth.serializer = _serializer;
    _auth.deserializer = _deserializer;
    _auth.strategies
        .add(new LocalAuthStrategy(_verifier(app.container.make(UserService))));

    await super.call(app);
    await app.configure(_auth);
  }

  bool loggedIn(RequestContext req) => req.session["userId"] != null;

  @Expose("/login", method: "POST")
  login(RequestContext req) async {
    // Include log-in logic here...
  }

  @Expose("/register", method: "POST")
  register(RequestContext req, UserService Users) async {
    // And your registration logic...
  }
}
