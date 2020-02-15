# cache
[![Pub](https://img.shields.io/pub/v/angel_cache.svg)](https://pub.dartlang.org/packages/angel_cache)
[![build status](https://travis-ci.org/angel-dart/cache.svg)](https://travis-ci.org/angel-dart/cache)

Support for server-side caching in [Angel](https://angel-dart.github.io).

## `CacheService`

A `Service` class that caches data from one service, storing it in another.
An imaginable use case is storing results from MongoDB or another database in
MemcacheD/Redis.

## `cacheSerializationResults`
A middleware that enables the caching of response serialization.

This can improve the performance of sending objects that are complex to serialize.
You can pass a [shouldCache] callback to determine which values should be cached.

```dart
main() async {
    var app = new Angel()..lazyParseBodies = true;
    
    app.use(
      '/api/todos',
      new CacheService(
        database: new AnonymousService(
          index: ([params]) {
            print('Fetched directly from the underlying service at ${new DateTime.now()}!');
            return ['foo', 'bar', 'baz'];
          },
          read: (id, [params]) {
            return {id: '$id at ${new DateTime.now()}'};
          }
        ),
      ),
    );
}
```

## `ResponseCache`
A flexible response cache for Angel.

Use this to improve real and perceived response of Web applications,
as well as to memoize expensive responses.

Supports the `If-Modified-Since` header, as well as storing the contents of
response buffers in memory.

To initialize a simple cache:

```dart
Future configureServer(Angel app) async {
  // Simple instance.
  var cache = new ResponseCache();
  
  // You can also pass an invalidation timeout.
  var cache = new ResponseCache(timeout: const Duration(days: 2));
  
  // Close the cache when the application closes.
  app.shutdownHooks.add((_) => cache.close());
  
  // Use `patterns` to specify which resources should be cached.
  cache.patterns.addAll([
    'robots.txt',
    new RegExp(r'\.(png|jpg|gif|txt)$'),
    new Glob('public/**/*'),
  ]);
  
  // REQUIRED: The middleware that serves cached responses
  app.use(cache.handleRequest);
  
  // REQUIRED: The response finalizer that saves responses to the cache
  app.responseFinalizers.add(cache.responseFinalizer);
}
```

### Purging the Cache
Call `invalidate` to remove a resource from a `ResponseCache`.

Some servers expect a reverse proxy or caching layer to support `PURGE` requests.
If this is your case, make sure to include some sort of validation (maybe IP-based)
to ensure no arbitrary attacker can hack your cache:

```dart
Future configureServer(Angel app) async {
  app.addRoute('PURGE', '*', (req, res) {
    if (req.ip != '127.0.0.1')
      throw new AngelHttpException.forbidden();
    return cache.purge(req.uri.path);
  });
}
```