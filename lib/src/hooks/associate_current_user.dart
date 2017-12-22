import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'errors.dart';
import 'is_server_side.dart';

/// Adds the authed user's id to `data`.
///
///Default [idField] is `'id'`.
/// Default [ownerField] is `'userId'`.
/// Default [userKey] is `'user'`.
HookedServiceEventListener associateCurrentUser(
    {String idField,
    String ownerField,
    userKey,
    String errorMessage,
    bool allowNullUserId: false,
    getId(user),
    assignUserId(id, obj)}) {
  return (HookedServiceEvent e) async {
    var fieldName = ownerField?.isNotEmpty == true ? ownerField : 'userId';
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
        return user[idField ?? 'id'];
      else if (idField == null || idField == 'id')
        return user.id;
      else
        return reflect(user).getField(new Symbol(idField ?? 'id')).reflectee;
    }

    var id = await _getId(user);

    if (id == null && allowNullUserId != true)
      throw new AngelHttpException.notProcessable(
          message: 'Current user is missing a $fieldName field.');

    _assignUserId(id, obj) {
      if (assignUserId != null)
        return assignUserId(id, obj);
      else if (obj is Map)
        obj[fieldName] = id;
      else if (fieldName == 'userId')
        obj.userId = id;
      else
        reflect(obj).setField(new Symbol(fieldName), id);
    }

    await _assignUserId(id, e.data);
  };
}
