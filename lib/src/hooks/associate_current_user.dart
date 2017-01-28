import 'package:angel_framework/angel_framework.dart';
import 'errors.dart';
import 'is_server_side.dart';

/// Adds the authed user's id to `data`.
///
/// Default [as] is `'userId'`.
/// Default [userKey] is `'user'`.
HookedServiceEventListener associateCurrentUser(
    {String as,
    String userKey,
    String errorMessage,
    bool allowNullUserId: false,
    getId(user),
    setId(id, user)}) {
  return (HookedServiceEvent e) async {
    var fieldName = as?.isNotEmpty == true ? as : 'userId';
    var user = e.request?.grab(userKey ?? 'user');

    if (user == null) {
      if (!isServerSide(e))
        throw new AngelHttpException.forbidden(
            message: errorMessage ?? Errors.NOT_LOGGED_IN);
      else
        return;
    }

    _getId(user) => getId == null ? user?.id : getId(user);

    var id = await _getId(user);

    if (id == null && allowNullUserId != true)
      throw new AngelHttpException.notProcessable(
          message: 'Current user is missing a $fieldName field.');

    _setId(id, user) {
      if (setId != null)
        return setId(id, user);
      else if (user is Map)
        user[fieldName] = id;
      else
        user.userId = id;
    }

    await _setId(id, e.data);
  };
}
