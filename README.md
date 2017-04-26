# angel_proxy

[![version 1.0.7](https://img.shields.io/badge/version-1.0.7-brightgreen.svg)](https://pub.dartlang.org/packages/angel_proxy)
[![build status](https://travis-ci.org/angel-dart/proxy.svg)](https://travis-ci.org/angel-dart/proxy)

Angel middleware to forward requests to another server (i.e. pub serve).

```dart
import 'package:angel_proxy/angel_proxy.dart';

main() async {
  // ...
  
  // Forward requests instead of serving statically
  await app.configure(new ProxyLayer('localhost', 3000));
  
  // Or, use one for pub serve.
  //
  // This automatically deactivates itself if the app is
  // in production.
  await app.configure(new PubServeLayer());
}
```

If your app's `storeOriginalBuffer` is `true`, then request bodies will be forwarded
as well, if they are not empty. This allows things like POST requests to function.
