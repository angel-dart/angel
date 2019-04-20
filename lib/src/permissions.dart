import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'hooks/errors.dart';
import 'hooks/restrict_to_owner.dart';

/// Easy mechanism to restrict access to services or routes.
class Permission {
  /// A string representation of the minimum required privilege required
  /// to access a resource.
  final String minimum;

  Permission(this.minimum);

  /// Creates a hook that restricts a service method to users with this
  /// permission, or if they are the resource [owner].
  ///
  /// [getId] and [getOwner] are passed to [restrictToOwner], along with
  /// [idField], [ownerField], [userKey] and [errorMessage].
  HookedServiceEventListener toHook<Id, Data, User>(
      {String errorMessage,
      String idField,
      String ownerField,
      bool owner = false,
      FutureOr<Iterable<String>> Function(User) getRoles,
      FutureOr<Id> Function(User) getId,
      FutureOr<Id> Function(Data) getOwnerId}) {
    return (HookedServiceEvent e) async {
      if (e.params.containsKey('provider')) {
        var user = await e.request?.container?.makeAsync<User>();

        if (user == null)
          throw AngelHttpException.forbidden(
              message: errorMessage ?? Errors.INSUFFICIENT_PERMISSIONS);

        var roleFinder = getRoles ?? (user) => <String>[];
        var roles = (await roleFinder(user)).toList();

        if (!roles.any(verify)) {
          // Try owner if the roles are not in-place
          if (owner == true) {
            var listener = restrictToOwner<Id, Data, User>(
                idField: idField,
                ownerField: ownerField,
                errorMessage: errorMessage,
                getId: getId,
                getOwnerId: getOwnerId);
            await listener(e);
          } else
            throw AngelHttpException.forbidden(
                message: errorMessage ?? Errors.INSUFFICIENT_PERMISSIONS);
        }
      }
    };
  }

  /// Restricts a route to users who have sufficient permissions.
  RequestHandler toMiddleware<User>({String message, getRoles(user)}) {
    return (RequestContext req, ResponseContext res) async {
      var user = await req.container.makeAsync<User>();

      if (user == null)
        throw AngelHttpException.forbidden(
            message: message ??
                'You have insufficient permissions to perform this action.');

      var roleFinder = getRoles ?? (user) async => user.roles ?? [];
      List<String> roles = (await roleFinder(user)).toList();

      if (!roles.any(verify))
        throw AngelHttpException.forbidden(
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

  factory PermissionBuilder.wildcard() => PermissionBuilder('*');

  PermissionBuilder operator +(other) {
    if (other is String)
      return add(other);
    else if (other is PermissionBuilder)
      return add(other._min);
    else if (other is Permission)
      return add(other.minimum);
    else
      throw ArgumentError(
          'Cannot add a ${other.runtimeType} to a PermissionBuilder.');
  }

  PermissionBuilder operator |(other) {
    if (other is String)
      return or(PermissionBuilder(other));
    else if (other is PermissionBuilder)
      return or(other);
    else if (other is Permission)
      return or(PermissionBuilder(other.minimum));
    else
      throw ArgumentError(
          'Cannot or a ${other.runtimeType} and a PermissionBuilder.');
  }

  /// Adds another level of [constraint].
  PermissionBuilder add(String constraint) =>
      PermissionBuilder('$_min:$constraint');

  /// Adds a wildcard permission.
  PermissionBuilder allowAll() => add('*');

  /// Duplicates this builder.
  PermissionBuilder clone() => PermissionBuilder(_min);

  /// Allows an alternative permission.
  PermissionBuilder or(PermissionBuilder other) =>
      PermissionBuilder('$_min | ${other._min}');

  /// Builds a [Permission].
  Permission toPermission() => Permission(_min);
}
