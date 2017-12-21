# poll
[![Pub](https://img.shields.io/pub/v/angel_poll.svg)](https://pub.dartlang.org/packages/angel_poll)
[![build status](https://travis-ci.org/angel-dart/poll.svg?branch=master)](https://travis-ci.org/angel-dart/poll)

`package:angel_client` support for "realtime" interactions with Angel via long polling.

Angel supports [WebSockets](https://github.com/angel-dart/websocket) on the server and client, which
makes it very straightforward to implement realtime collections. However, not every user's browser
supports WebSockets. In such a case, applications might *gracefully degrade* to long-polling
the server for changes.

A `PollingService` wraps a client-side `Service` (typically a REST-based one), and calls its
`index` method at a regular interval.  After indexing, the `PollingService` performs a diff
and identifies whether items have been created, modified, or removed. The updates are sent out
through `onCreated`, `onModified`, etc., effectively managing a real-time collection of data.

A common use-case would be passing this service to `ServiceList`, a class that manages the state
of a collection managed in real-time.

```dart
import 'package:angel_client/io.dart';
import 'package:angel_poll/angel_poll.dart';

main() {
  var app = new Rest('http://localhost:3000');

  var todos = new ServiceList(
    new PollingService(
      // Typically, you'll pass a REST-based service instance here.
      app.service('api/todos'),

      // `index` called every 5 seconds
      const Duration(seconds: 5),
    ),
  );

  todos.onChange.listen((_) {
    // Something happened here.
    // Maybe an item was created, modified, etc.
  });
}
```