import 'package:angel_framework/angel_framework.dart';
import 'errors.dart';
import 'is_server_side.dart';

/// Restricts the service method to authed users only.
HookedServiceEventListener restrictToAuthenticated(
    {userKey, String errorMessage}) {
  return (HookedServiceEvent e) async {
    var user = e.request?.grab(userKey ?? 'user');

    if (user == null) {
      if (!isServerSide(e))
        throw new AngelHttpException.forbidden(
            message: errorMessage ?? Errors.NOT_LOGGED_IN);
      else
        return;
    }
  };
}
