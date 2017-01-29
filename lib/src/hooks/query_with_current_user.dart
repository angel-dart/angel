import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'errors.dart';
import 'is_server_side.dart';

/// Adds the authed user's id to `params['query']`.
///
/// Default [as] is `'userId'`.
/// Default [userKey] is `'user'`.
HookedServiceEventListener queryWithCurrentUser(
    {String as,
    String idField,
    String userKey,
    String errorMessage,
    bool allowNullUserId: false,
    getId(user)}) {
  return (HookedServiceEvent e) async {
    var fieldName = idField?.isNotEmpty == true ? idField : 'id';
    var user = e.request?.grab(userKey ?? 'user');

    if (user == null) {
      if (!isServerSide(e))
        throw new AngelHttpException.forbidden(
            message: errorMessage ?? Errors.NOT_LOGGED_IN);
      else
        return;
    }

    _getId(user) {
      if (getId != null)
        return getId(user);
      else if (user is Map)
        return user[fieldName];
      else if (user is Extensible)
        return user.properties[fieldName];
      else if (fieldName == 'id')
        return user.id;
      else
        return reflect(user).getField(new Symbol(fieldName)).reflectee;
    }

    var id = await _getId(user);

    if (id == null && allowNullUserId != true)
      throw new AngelHttpException.notProcessable(
          message: 'Current user is missing a \'$fieldName\' field.');

    var data = {as?.isNotEmpty == true ? as : 'userId': id};

    e.params['query'] = e.params.containsKey('query')
        ? (e.params['query']..addAll(data))
        : data;
  };
}
