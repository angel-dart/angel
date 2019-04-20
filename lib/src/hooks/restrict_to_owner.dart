import 'dart:async';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'errors.dart';
import 'is_server_side.dart';

/// Restricts users to accessing only their own resources.
HookedServiceEventListener restrictToOwner<Id, Data, User>(
    {String idField,
    String ownerField,
    String errorMessage,
    FutureOr<Id> Function(User) getId,
    FutureOr<Id> Function(Data) getOwnerId}) {
  return (HookedServiceEvent e) async {
    if (!isServerSide(e)) {
      var user = await e.request?.container?.makeAsync<User>();

      if (user == null)
        throw AngelHttpException.notAuthenticated(
            message:
                'The current user is missing. You must not be authenticated.');

      Future<Id> _getId(User user) async {
        if (getId != null)
          return getId(user);
        else if (user is Map)
          return user[idField ?? 'id'];
        else
          return reflect(user).getField(Symbol(idField ?? 'id')).reflectee;
      }

      var id = await _getId(user);

      if (id == null) throw Exception('The current user has no ID.');

      var resource = await e.service.read(
          e.id,
          {}
            ..addAll(e.params ?? {})
            ..remove('provider')) as Data;

      if (resource != null) {
        Future<Id> _getOwner(Data obj) async {
          if (getOwnerId != null)
            return await getOwnerId(obj);
          else if (obj is Map)
            return obj[ownerField ?? 'user_id'];
          else
            return reflect(obj)
                .getField(Symbol(ownerField ?? 'userId'))
                .reflectee;
        }

        var ownerId = await _getOwner(resource);

        if ((ownerId is Iterable && !ownerId.contains(id)) || ownerId != id)
          throw AngelHttpException.forbidden(
              message: errorMessage ?? Errors.INSUFFICIENT_PERMISSIONS);
      }
    }
  };
}
