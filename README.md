# proxy
[![Pub](https://img.shields.io/pub/v/angel_proxy.svg)](https://pub.dartlang.org/packages/angel_proxy)
[![build status](https://travis-ci.org/angel-dart/proxy.svg)](https://travis-ci.org/angel-dart/proxy)

Angel middleware to forward requests to another server (i.e. `pub serve`).

```dart
import 'package:angel_proxy/angel_proxy.dart';
import 'package:http/http.dart' as http;

main() async {
  // ...
  
  var client = new http.Client();
  var proxy = new Proxy(app, client, 'http://localhost:3000');
  
  // Forward requests instead of serving statically
  app.use(proxy.handleRequest);
}
```

You can also restrict the proxy to serving only from a specific root:
```dart
new Proxy(app, client, '<host>', publicPath: '/remote');
```

Also, you can map requests to a root path on the remote server
```dart
new Proxy(app, client, '<host>', mapTo: '/path');
```

If your app's `storeOriginalBuffer` is `true`, then request bodies will be forwarded
as well, if they are not empty. This allows things like POST requests to function.
