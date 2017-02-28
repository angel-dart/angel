import 'package:angel_framework/angel_framework.dart';
import '../permissions.dart';

/// Generates a [Permission] based on the situation, and runs it as a hook.
///
/// This is ideal for cases when you want to limit permissions to a dynamic
/// resource.
HookedServiceEventListener variantPermission(
    createPermission(HookedServiceEvent e),
    {String errorMessage,
    userKey,
    bool owner: false,
    getRoles(user),
    getId(user),
    getOwner(obj)}) {
  return (HookedServiceEvent e) async {
    var permission = await createPermission(e);

    if (permission is PermissionBuilder) permission = permission.toPermission();

    if (permission is! Permission)
      throw new ArgumentError(
          'createPermission must generate a Permission, whether synchronously or asynchronously.');
    await permission.toHook(
        errorMessage: errorMessage,
        userKey: userKey,
        owner: owner,
        getRoles: getRoles,
        getId: getId,
        getOwner: getOwner)(e);
  };
}
