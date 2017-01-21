import 'package:angel_framework/angel_framework.dart';

/// Easy mechanism to restrict access to services or routes.
class Permission {
  final String minimum;

  Permission(this.minimum);

  call(RequestContext req, ResponseContext res) {
    return toMiddleware()(req, res);
  }

  HookedServiceEventListener toHook(
      {String message, String userKey, getRoles(user)}) {
    return (HookedServiceEvent e) async {
      if (e.params.containsKey('provider')) {
        var user = e.request.grab(userKey ?? 'user');

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
      }
    };
  }

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

class PermissionBuilder {
  String _min;

  PermissionBuilder(this._min);

  factory PermissionBuilder.wildcard() => new PermissionBuilder('*');

  call(RequestContext req, ResponseContext res) => toPermission()(req, res);

  PermissionBuilder add(String constraint) =>
      new PermissionBuilder('$_min:$constraint');

  PermissionBuilder allowAll() => add('*');

  PermissionBuilder clone() => new PermissionBuilder(_min);

  PermissionBuilder or(PermissionBuilder other) =>
      new PermissionBuilder('$_min | ${other._min}');

  Permission toPermission() => new Permission(_min);
}
