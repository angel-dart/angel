part of angel_framework.http;

/// Annotation to map middleware onto a handler.
class Middleware {
  final List handlers;

  const Middleware(List this.handlers);
}

/// Annotation to set a service up to release hooks on every action.
class Hooked {
  const Hooked();
}

class Expose {
  final String method;
  final Pattern path;
  final List middleware;
  final String as;
  final List<String> allowNull;

  const Expose(Pattern this.path,
      {String this.method: "GET",
      List this.middleware: const [],
      String this.as: null,
      List<String> this.allowNull: const[]});
}