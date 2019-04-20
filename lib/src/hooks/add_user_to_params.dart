import 'package:angel_framework/angel_framework.dart';

/// Adds the authed user to `e.params`, only if present in `req.container`.
HookedServiceEventListener addUserToParams<User>({String as}) {
  return (HookedServiceEvent e) async {
    var user = await e.request?.container?.makeAsync<User>();
    if (user != null) e.params[as ?? 'user'] = user;
  };
}
