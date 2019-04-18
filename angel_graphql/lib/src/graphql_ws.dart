import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_validate/server.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';
import 'package:graphql_server/subscriptions_transport_ws.dart' as stw;
import 'package:web_socket_channel/io.dart';

/// A [RequestHandler] that serves a spec-compliant GraphQL backend, over WebSockets.
/// This endpoint only supports WebSockets, and can be used to deliver subscription events.
///
/// `graphQLWS` uses the Apollo WebSocket protocol, for the sake of compatibility with
/// existing tooling.
///
/// See:
/// * https://github.com/apollographql/subscriptions-transport-ws
RequestHandler graphQLWS(GraphQL graphQL) {
  return (req, res) async {
    if (req is HttpRequestContext) {
      if (WebSocketTransformer.isUpgradeRequest(req.rawRequest)) {
        await res.detach();
        var socket = await WebSocketTransformer.upgrade(req.rawRequest);
        var channel = IOWebSocketChannel(socket);
        var client = stw.RemoteClient(channel.cast<String>());
        var server = _GraphQLWSServer(client, graphQL, req, res);
        await server.done;
      } else {
        throw AngelHttpException.badRequest(
            message: 'The `graphQLWS` endpoint only accepts WebSockets.');
      }
    } else {
      throw AngelHttpException.badRequest(
          message: 'The `graphQLWS` endpoint only accepts HTTP/1.1 requests.');
    }
  };
}

class _GraphQLWSServer extends stw.Server {
  final GraphQL graphQL;
  final RequestContext req;
  final ResponseContext res;

  _GraphQLWSServer(stw.RemoteClient client, this.graphQL, this.req, this.res)
      : super(client);

  @override
  bool onConnect(stw.RemoteClient client, [Map connectionParams]) => true;

  @override
  Future<stw.GraphQLResult> onOperation(String id, String query,
      [Map<String, dynamic> variables, String operationName]) async {
    try {
      var globalVariables = <String, dynamic>{
        '__requestctx': req,
        '__responsectx': res,
      };
      var data = await graphQL.parseAndExecute(
        query,
        operationName: operationName,
        sourceUrl: 'input',
        globalVariables: globalVariables,
      );
      return stw.GraphQLResult(data);
    } on GraphQLException catch (e) {
      return stw.GraphQLResult(null, errors: e.errors);
    }
  }
}
