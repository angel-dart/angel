part of angel.routes.controllers;

@Expose("/auth")
class AuthController extends Controller {
  @override
  call(Angel app) async {
    app.registerMiddleware("auth", (req, res) async {
      if (req.session['userId'] == null)
        throw new AngelHttpException.Forbidden();

      return true;
    });
  }

  @Expose("/login", method: "POST")
  login(RequestContext req) async {
    // Include log-in logic here...
  }
}
