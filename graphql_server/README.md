# graphql_server
Base package for implementing GraphQL servers.
You might prefer [`package:angel_graphql`](https://github.com/angel-dart/graphql),
the fastest way to implement GraphQL backends in Dart.

`package:graphql_server` does not require any specific
framework, and thus can be used in any Dart project.

## Ad-hoc Usage
The actual querying functionality is handled by the
`GraphQL` class, which takes a schema (from `package:graphql_schema`).
In most cases, you'll want to call `parseAndExecute`
on some string of GraphQL text. It returns either a `Stream`
or `Map<String, dynamic>`, and can potentially throw
a `GraphQLException` (which is JSON-serializable):

```dart
try {
    var data = await graphQL.parseExecute(responseText);

    if (data is Stream) {
        // Handle a subscription somehow...
    } else {
        response.send({'data': data});
    }
} on GraphQLException catch(e) {
    response.send(e.toJson());
}
```

Consult the API reference for more:
https://pub.dartlang.org/documentation/graphql_server/latest/graphql_server/GraphQL/parseAndExecute.html

If you're looking for functionality like `graphQLHttp`
in `graphql-js`, that is not included in this package, because
it is typically specific to the framework/platform you are using.
The `graphQLHttp` implementation in `package:angel_graphql` is
a good example:
https://github.com/angel-dart/graphql/blob/master/angel_graphql/lib/src/graphql_http.dart

## Subscriptions
GraphQL queries involving `subscription` operations can return
a `Stream`. Ultimately, the transport for relaying subscription
events to clients is not specified in the GraphQL spec, so it's
up to you.

For the purposes of reusing existing tooling (i.e. JS clients, etc.),
`package:graphql_server` rolls with an implementation of Apollo's
`subscriptions-transport-ws` spec.

**NOTE: At this point, Apollo's spec is extremely out-of-sync with the protocol their client actually expects.**
**See the following issue to track this:**
**https://github.com/apollographql/subscriptions-transport-ws/issues/551**

The implementation is built on `package:stream_channel`, and 
therefore can be used on any two-way transport, whether it is
WebSockets, TCP sockets, Isolates, or otherwise.

Users of this package are expected to extend the `Server`
abstract class. `Server` will handle the transport and communication,
but again, ultimately, emitting subscription events is up to your
implementation.

Here's a snippet from `graphQLWS` in `package:angel_graphql`.
It runs within the context of one single request:

```dart
var channel = IOWebSocketChannel(socket);
var client = stw.RemoteClient(channel.cast<String>());
var server =
    _GraphQLWSServer(client, graphQL, req, res, keepAliveInterval);
await server.done;
```

See `graphQLWS` in `package:angel_graphql` for a good example:
https://github.com/angel-dart/graphql/blob/master/angel_graphql/lib/src/graphql_ws.dart