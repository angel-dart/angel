part of angel_route.src.router;

/// Placeholder [Route] to serve as a symbolic link
/// to a mounted [Router].
class SymlinkRoute extends Route {
  final Pattern pattern;
  final Router router;

  SymlinkRoute(Pattern path, this.pattern, this.router) : super(path);
}
