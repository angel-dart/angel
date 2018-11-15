# sync
[![Pub](https://img.shields.io/pub/v/angel_sync.svg)](https://pub.dartlang.org/packages/angel_sync)
[![build status](https://travis-ci.org/angel-dart/sync.svg)](https://travis-ci.org/angel-dart/sync)

Easily synchronize and scale WebSockets using package:pub_sub.

# Usage
This package exposes `PubSubSynchronizationChannel`, which
can simply be dropped into any `AngelWebSocket` constructor.

Once you've set that up, instances of your application will
automatically fire events in-sync. That's all you have to do
to scale a real-time application with Angel!

```dart
await app.configure(new AngelWebSocket(
    synchronizationChannel: new PubSubSynchronizationChannel(
        new pub_sub.IsolateClient('<client-id>', adapter.receivePort.sendPort),
    ),
));
```