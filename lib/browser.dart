import 'dart:async' show Stream, StreamController;
import 'dart:html' show AnchorElement, window;
import 'angel_route.dart';

final RegExp _hash = new RegExp(r'^#/');

/// A variation of the [Router] support both hash routing and push state.
abstract class BrowserRouter extends Router {
  /// Fires whenever the active route changes. Fires `null` if none is selected (404).
  Stream<Route> get onRoute;

  /// Set `hash` to true to use hash routing instead of push state.
  /// `listen` as `true` will call `listen` after initialization.
  factory BrowserRouter({bool hash: false, bool listen: true, Route root}) {
    return hash
        ? new _HashRouter(listen: listen, root: root)
        : new _PushStateRouter(listen: listen, root: root);
  }

  BrowserRouter._([Route root]) : super(root: root);

  /// Calls `goTo` on the [Route] matching `path`.
  void go(String path, [Map params]);

  /// Navigates to the given route.
  void goTo(Route route, [Map params]);

  /// Begins listen for location changes.
  void listen();
}

class _BrowserRouterImpl extends Router implements BrowserRouter {
  Route _current;
  StreamController<Route> _onRoute = new StreamController<Route>();
  Route get currentRoute => _current;

  @override
  Stream<Route> get onRoute => _onRoute.stream;

  _BrowserRouterImpl({bool listen, Route root}) : super(root: root) {
    if (listen) this.listen();
    prepareAnchors();
  }

  @override
  void go(String path, [Map params]) {
    final resolved = resolve(path);

    if (resolved != null)
      goTo(resolved, params);
    else
      throw new RoutingException.noSuchRoute(path);
  }

  void prepareAnchors() {
    final anchors = window.document.querySelectorAll('a:not([dynamic])');

    for (final AnchorElement $a in anchors) {
      if ($a.attributes.containsKey('href') &&
          !$a.attributes.containsKey('download') &&
          !$a.attributes.containsKey('target') &&
          $a.attributes['rel'] != 'external') {
        $a.onClick.listen((e) {
          e.preventDefault();
          go($a.attributes['href']);
        });
      }

      $a.attributes['dynamic'] = 'true';
    }
  }
}

class _HashRouter extends _BrowserRouterImpl {
  _HashRouter({bool listen, Route root}) : super(listen: listen, root: root) {
    if (listen) this.listen();
  }

  @override
  void goTo(Route route, [Map params]) {
    route.state.properties.addAll(params ?? {});
    window.location.hash = '#/${route.makeUri(params)}';
    _onRoute.add(route);
  }

  @override
  void listen() {
    window.onHashChange.listen((_) {
      final path = window.location.hash.replaceAll(_hash, '');
      final resolved = resolve(path);

      if (resolved == null || (path.isEmpty && resolved == root)) {
        _onRoute.add(_current = null);
      } else if (resolved != null && resolved != _current) {
        goTo(resolved);
      }
    });
  }
}

class _PushStateRouter extends _BrowserRouterImpl {
  _PushStateRouter({bool listen, Route root})
      : super(listen: listen, root: root) {
    if (listen) this.listen();
  }

  @override
  void goTo(Route route, [Map params]) {
    window.history.pushState(
        {'path': route.path, 'params': params ?? {}, 'properties': properties},
        route.name ?? route.path,
        route.makeUri(params));
    _onRoute.add(_current = route..state.properties.addAll(params ?? {}));
  }

  @override
  void listen() {
    window.onPopState.listen((e) {
      if (e.state is Map && e.state.containsKey('path')) {
        final resolved = resolve(e.state['path']);

        if (resolved != _current) {
          properties.addAll(e.state['properties'] ?? {});
          _onRoute.add(_current = resolved
            ..state.properties.addAll(e.state['params'] ?? {}));
        }
      } else
        _onRoute.add(_current = null);
    });
  }
}
