part of angel.routes.controllers;

@Expose("/auth")
class AuthController extends Controller {
  @override
  call(Angel app) async {
    await super.call(app);

    app.registerMiddleware("auth", (req, res) async {
      if (!loggedIn(req)) throw new AngelHttpException.Forbidden();

      return true;
    });
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
