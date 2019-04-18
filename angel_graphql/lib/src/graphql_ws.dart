import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_validate/server.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';

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
        // TODO: Apollo protocol
        throw UnimplementedError('Apollo protocol not yet implemented.');
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
