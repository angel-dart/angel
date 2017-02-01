import 'package:angel_framework/angel_framework.dart';
import 'hooks/errors.dart';
import 'hooks/restrict_to_owner.dart';

/// Easy mechanism to restrict access to services or routes.
class Permission {
  /// A string representation of the minimum required privilege required
  /// to access a resource.
  final String minimum;

  Permission(this.minimum);

  call(RequestContext req, ResponseContext res) {
    return toMiddleware()(req, res);
  }

  /// Creates a hook that restricts a service method to users with this
  /// permission, or if they are the resource [owner].
  ///
  /// [getId] and [getOwner] are passed to [restrictToOwner], along with
  /// [idField], [ownerField], [userKey] and [errorMessage].
  HookedServiceEventListener toHook(
      {String errorMessage,
      String idField,
      String ownerField,
      String userKey,
      bool owner: false,
      getRoles(user),
      getId(user),
      getOwner(obj)}) {
    return (HookedServiceEvent e) async {
      if (e.params.containsKey('provider')) {
        var user = e.request?.grab(userKey ?? 'user');

        if (user == null)
          throw new AngelHttpException.forbidden(
              message: errorMessage ?? Errors.INSUFFICIENT_PERMISSIONS);

        var roleFinder = getRoles ?? (user) async => user.roles ?? [];
        List<String> roles = (await roleFinder(user)).toList();

        if (!roles.any(verify)) {
          // Try owner if the roles are not in-place
          if (owner == true) {
            var listener = restrictToOwner(
                idField: idField,
                ownerField: ownerField,
                userKey: userKey,
                errorMessage: errorMessage,
                getId: getId,
                getOwner: getOwner);
            await listener(e);
          } else
            throw new AngelHttpException.forbidden(
                message: errorMessage ?? Errors.INSUFFICIENT_PERMISSIONS);
        }
      }
    };
  }

  /// Restricts a route to users who have sufficient permissions.
  RequestMiddleware toMiddleware(
      {String message, String userKey, getRoles(user)}) {
    return (RequestContext req, ResponseContext res) async {
      var user = req.grab(userKey ?? 'user');

      if (user == null)
        throw new AngelHttpException.forbidden(
            message: message ??
                'You have insufficient permissions to perform this action.');

      var roleFinder = getRoles ?? (user) async => user.roles ?? [];
      List<String> roles = (await roleFinder(user)).toList();

      if (!roles.any(verify))
        throw new AngelHttpException.forbidden(
            message: message ??
                'You have insufficient permissions to perform this action.');

      return true;
    };
  }

  /// Returns `true` if the [given] permission string
  /// represents a sufficient permission, matching the [minimum].
  bool verify(String given) {
    bool verifyOne(String minimum) {
      if (minimum == '*') return true;

      var minSplit = minimum.split(':');
      var split = given.split(':');

      for (int i = 0; i < minSplit.length; i++) {
        if (i >= split.length) return false;
        var min = minSplit[i], giv = split[i];

        if (min == '*' || min == giv) {
          if (i >= minSplit.length - 1)
            return true;
          else
            continue;
        } else
          return false;
      }

      return false;
    }

    var minima = minimum
        .split('|')
        .map((str) => str.trim())
        .where((str) => str.isNotEmpty);
    return minima.any(verifyOne);
  }

  @override
  String toString() => 'Permission: $minimum';
}

/// Builds [Permission]s.
class PermissionBuilder {
  String _min;

  /// A minimum
  PermissionBuilder(this._min);

  factory PermissionBuilder.wildcard() => new PermissionBuilder('*');

  PermissionBuilder operator +(other) {
    if (other is String)
      return add(other);
    else if (other is PermissionBuilder)
      return add(other._min);
    else if (other is Permission)
      return add(other.minimum);
    else
      throw new ArgumentError(
          'Cannot add a ${other.runtimeType} to a PermissionBuilder.');
  }

  PermissionBuilder operator |(other) {
    if (other is String)
      return or(new PermissionBuilder(other));
    else if (other is PermissionBuilder)
      return or(other);
    else if (other is Permission)
      return or(new PermissionBuilder(other.minimum));
    else
      throw new ArgumentError(
          'Cannot or a ${other.runtimeType} and a PermissionBuilder.');
  }

  call(RequestContext req, ResponseContext res) => toPermission()(req, res);

  /// Adds another level of [constraint].
  PermissionBuilder add(String constraint) =>
      new PermissionBuilder('$_min:$constraint');

  /// Adds a wildcard permission.
  PermissionBuilder allowAll() => add('*');

  /// Duplicates this builder.
  PermissionBuilder clone() => new PermissionBuilder(_min);

  /// Allows an alternative permission.
  PermissionBuilder or(PermissionBuilder other) =>
      new PermissionBuilder('$_min | ${other._min}');

  /// Builds a [Permission].
  Permission toPermission() => new Permission(_min);
}
