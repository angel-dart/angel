# wings
Native HTTP driver for Angel, for a nice speed boost.

Not ready for production.

## How does it work?
Typically, Angel uses the `AngelHttp` driver, which is wrapper over the `HttpServer` functionality in
`dart:io`, which in turns uses the `ServerSocket` and `Socket` functionality. This is great - Dart's standard
library comes with an HTTP server, which saves a lot of difficult in implementation.

However, abstraction tends to come with a cost. Wings seeks to minimize abstraction entirely. Rather than
using the built-in Dart network stack, Wings' HTTP server is implemented in C++ as a Dart native extension,
and the `AngelWings` driver listens to events from the extension and converts them directly into
`RequestContext` objects, without any additional abstraction within. This reduces the amount of computation
performed on each request, and helps to minimize response latency. Sending data from the response buffer in plain
Dart surprisingly is the most expensive operation, as is revealed by the Observatory.

By combining Dart's powerful VM with a native code server based on
[the same one used in Node.js](https://github.com/nodejs/http-parser),
`AngelWings` trims several milliseconds off every request, both saving resources and reducing
load times for high-traffic applications.

## How can I use it?
The intended way to use `AngelWings` is via
[`package:build_native`](https://github.com/thosakwe/build_native);
however, the situation surrounding distributing native extensions is yet far from ideal,
so this package includes pre-built binaries out-of-the-box.

Thanks to this, you can use it like any other Dart package, by installing it via Pub.

## Brief example
Using `AngelWings` is almost identical to using `AngelHttp`; however, it does
not support SSL, and therefore should be placed behind a reverse proxy like `nginx` in production.

```dart
main() async {
  var app = new Angel();
  var wings = new AngelWings(app, shared: true, useZone: false);

  app.injectEncoders({'gzip': gzip.encoder, 'deflate': zlib.encoder});

  app.get('/hello', 'Hello, native world! This is Angel WINGS.');

  var fs = const LocalFileSystem();
  var vDir = new VirtualDirectory(app, fs, source: fs.directory('web'));
  app.use(vDir.handleRequest);

  await wings.startServer('127.0.0.1', 3000);
  print('Listening at http://${wings.address.address}:${wings.port}');
}
```