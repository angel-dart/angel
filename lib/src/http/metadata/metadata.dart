part of angel_framework.http;

/// Maps the given middleware(s) onto this handler.
class Middleware {
  final List handlers;

  const Middleware(List this.handlers);
}

/// This service will send an event after every action.
class Hooked {
  const Hooked();
}