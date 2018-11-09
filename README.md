# proxy
[![Pub](https://img.shields.io/pub/v/angel_proxy.svg)](https://pub.dartlang.org/packages/angel_proxy)
[![build status](https://travis-ci.org/angel-dart/proxy.svg)](https://travis-ci.org/angel-dart/proxy)

Angel middleware to forward requests to another server (i.e. `webdev serve`).
Also supports WebSockets.

```dart
import 'package:angel_proxy/angel_proxy.dart';
import 'package:http/http.dart' as http;

main() async {
  // ...
  
  var client = http.Client();
  
  // Forward requests instead of serving statically
  var proxy1 = Proxy(client, Uri.parse('http://localhost:3000'));
  
  // handle all methods (GET, POST, ...)
  app.fallback(proxy.handleRequest);
}
```

You can also restrict the proxy to serving only from a specific root:
```dart
Proxy(client, baseUrl, publicPath: '/remote');
```

Also, you can map requests to a root path on the remote server:
```dart
Proxy(client, baseUrl.replace(path: '/path'));
```

If your app's `keepRawRequestBuffers` is `true`, then request bodies will be forwarded
as well, if they are not empty. This allows things like POST requests to function.
