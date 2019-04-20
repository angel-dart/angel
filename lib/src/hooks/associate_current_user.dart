import 'dart:async';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'errors.dart';
import 'is_server_side.dart';

/// Adds the authed user's id to `data`.
///
///Default [idField] is `'id'`.
/// Default [ownerField] is `'userId'`.
HookedServiceEventListener associateCurrentUser<Id, Data, User>(
    {String idField,
    String ownerField,
    String errorMessage,
    bool allowNullUserId = false,
    FutureOr<Id> Function(User) getId,
    FutureOr<Data> Function(Id, Data) assignUserId}) {
  return (HookedServiceEvent e) async {
    var fieldName = ownerField?.isNotEmpty == true ? ownerField : 'userId';
    var user = await e.request?.container?.makeAsync<User>();

    if (user == null) {
      if (!isServerSide(e))
        throw AngelHttpException.forbidden(
            message: errorMessage ?? Errors.NOT_LOGGED_IN);
      else
        return;
    }

    Future<Id> _getId(User user) async {
      if (getId != null)
        return await getId(user);
      else if (user is Map)
        return user[idField ?? 'id'];
      else
        return reflect(user).getField(Symbol(idField ?? 'id')).reflectee;
    }

    var id = await _getId(user);

    if (id == null && allowNullUserId != true)
      throw AngelHttpException.notProcessable(
          message: 'Current user is missing a $fieldName field.');

    Future<Data> _assignUserId(Id id, Data obj) async {
      if (assignUserId != null)
        return assignUserId(id, obj);
      else if (obj is Map)
        return obj..[fieldName] = id;
      else {
        reflect(obj).setField(Symbol(fieldName), id);
        return obj;
      }
    }

    e.data = await _assignUserId(id, e.data);
  };
}
