library angel_framework.http.metadata;

import 'hooked_service.dart' show HookedServiceEventListener;

/// Annotation to map middleware onto a handler.
class Middleware {
  final List handlers;

  const Middleware(this.handlers);
}

/// Annotation to set a service up to release hooks on every action.
class Hooked {
  const Hooked();
}

const Hooked hooked = const Hooked();

/// Attaches hooks to a [HookedService].
class Hooks {
  final List<HookedServiceEventListener> before;
  final List<HookedServiceEventListener> after;

  const Hooks({this.before: const [], this.after: const []});
}

/// Exposes a [Controller] to the Internet.
class Expose {
  final String method;
  final Pattern path;
  final List middleware;
  final String as;
  final List<String> allowNull;

  const Expose(this.path,
      {this.method: "GET",
      this.middleware: const [],
      this.as: null,
      this.allowNull: const []});
}
