import 'package:angel_framework/angel_framework.dart';

/// Adds the authed user to `e.params`, only if present in `req.injections`.
HookedServiceEventListener addUserToParams({String as, userKey}) {
  return (HookedServiceEvent e) {
    var user = e.request?.grab(userKey ?? 'user');

    if (user != null) e.params[as ?? 'user'] = user;
  };
}
