part of angel_route.src.router;

/// Placeholder [Route] to serve as a symbolic link
/// to a mounted [Router].
class SymlinkRoute<T> extends Route<T> {
  final Router<T> router;
  SymlinkRoute(String path, this.router)
      : super(path, method: null, handlers: null);
}
