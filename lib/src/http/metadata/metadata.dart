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