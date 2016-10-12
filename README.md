# angel_route
A powerful, isomorphic routing library for Dart.

This API is a huge improvement over the original [Angel](https://github.com/angel-dart/angel)
routing system, and thus deserves to be its own individual project.

`angel_route` exposes a routing system that takes the shape of a tree. This tree structure
can be easily navigated, in a fashion somewhat similar to a filesystem. The `Router` API
is a very straightforward interface that allows for your code to take a shape similar to
the route tree. Users of Laravel and Express will be very happy.

`angel_route` does not require the use of [Angel](https://github.com/angel-dart/angel),
and has no dependencies. Thus, it can be used in any application, regardless of
framework. This includes Web apps, Flutter apps, CLI apps, and smaller servers which do
not need all the features of the Angel framework.

# Contents

* [Examples](#examples)
    * [Routing](#routing)
    * [Tree Hierarchy and Path Resolution](#hierarchy)
* [In the Browser](#in-the-browser)
* [Route State](#route-state)
* [Route Parameters](#route-parameters)
    
# Examples

## Routing
If you use [Angel](https://github.com/angel-dart/angel), every `Angel` instance is
a `Router` in itself.

```dart

main() {
  final router = new Router();
  
  router.get('/users', () {});
  
  router.post('/users/:id/timeline', (String id) {});
  
  router.get('/square_root/:id([0-9]+)', (String id) {
    final n = num.parse(id);
    return {'result': pow(n, 2) };
  });
  
  router.group('/show/:id', (router) {
    router.get('/reviews', (id) {
      return someQuery(id).reviews;
    });
    
    // Optionally restrict params to a RegExp
    router.get('/reviews/:reviewId([A-Za-z0-9_]+)', (id, reviewId) {
      return someQuery(id).reviews.firstWhere(
        (r) => r.id == reviewId);
    });
  }, before: [put, middleware, here]);
}
```

The default `Router` does not give any notification of routes being changed, because
there is no inherent stream of URL's for it to listen to. This is good, because a server
needs a lot of flexibility with which to handle requests.

## Hierarchy

```dart
main() {
    final foo = new Route('/');
    final bar = foo.child('bar');
    final baz = foo.child('baz');
    
    final a = bar.child('a');
    
    /*
     * Relative paths:
     * a.resolve('../baz') = baz;
     * bar.resolve('a') = a;
     * 
     * Absolute paths:
     * a.resolve('/bar/a') = a;
     */
}
```

```dart
main() {
  final router = new Router();
  
  router.group('/user/:id', (router) {
    router.get('/balance', (id) async {
      final user = await someQuery(id);
      return user.balance;
    });
  });
}
```

See [the tests](test/route/no_params.dart) for good examples.

# In the Browser
Supports both hashed routes and pushState. The `BrowserRouter` interface exposes
a `Stream<Route> onRoute`, which can be listened to for changes. It will fire `null`
whenever no route is matched.

```dart
main() {
  
}
```

`angel_route` will also automatically intercept `<a>` elements and redirect them to
your routes.

To prevent this for a given anchor, do any of the following:
  * Do not provide an `href`
  * Provide a `download` or `target` attribute on the element
  * Set `rel="external"`
  
# Route State
Routes can have state via the `Extensible` class, which is a simple proxy over a `Map`.
This does not require reflection, and can be used in all Dart environments.

```dart
main() {
  final router = new BrowserRouter();
  // ..
  router.onRoute.listen((route) {
    if (route == null)
      throw 404;
    else route.state.foo = 'bar';
  });
}
```

# Route Parameters
Routes can have parameters, as seen in the above examples.
If a parameter is a numeber, then it will automatically be parsed.