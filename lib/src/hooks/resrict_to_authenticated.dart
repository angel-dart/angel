import 'package:angel_framework/angel_framework.dart';
import 'errors.dart';
import 'is_server_side.dart';

/// Restricts the service method to authed users only.
HookedServiceEventListener restrictToAuthenticated<User>(
    {String errorMessage}) {
  return (HookedServiceEvent e) async {
    var user = await e.request?.container?.makeAsync<User>();

    if (user == null) {
      if (!isServerSide(e))
        throw AngelHttpException.forbidden(
            message: errorMessage ?? Errors.NOT_LOGGED_IN);
      else
        return;
    }
  };
}
