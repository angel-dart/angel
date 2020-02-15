import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/server.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';

final ContentType graphQlContentType = ContentType('application', 'graphql');

final Validator graphQlPostBody = Validator({
  'query*': isNonEmptyString,
  'operation_name': isNonEmptyString,
  'variables': predicate((v) => v == null || v is String || v is Map),
});

final RegExp _num = RegExp(r'^[0-9]+$');

/// A [RequestHandler] that serves a spec-compliant GraphQL backend.
///
/// Follows the guidelines listed here:
/// https://graphql.org/learn/serving-over-http/
RequestHandler graphQLHttp(GraphQL graphQL,
    {Function(RequestContext, ResponseContext, Stream<Map<String, dynamic>>)
        onSubscription}) {
  return (req, res) async {
    var globalVariables = <String, dynamic>{
      '__requestctx': req,
      '__responsectx': res,
    };

    sendGraphQLResponse(result) async {
      if (result is Stream<Map<String, dynamic>>) {
        if (onSubscription == null) {
          throw StateError(
              'The GraphQL backend returned a Stream, but no `onSubscription` callback was provided.');
        } else {
          return await onSubscription(req, res, result);
        }
      }

      return {
        'data': result,
      };
    }

    executeMap(Map map) async {
      var body = await req.parseBody().then((_) => req.bodyAsMap);
      var text = body['query'] as String;
      var operationName = body['operation_name'] as String;
      var variables = body['variables'];

      if (variables is String) {
        variables = json.decode(variables as String);
      }

      return await sendGraphQLResponse(await graphQL.parseAndExecute(
        text,
        sourceUrl: 'input',
        operationName: operationName,
        variableValues: foldToStringDynamic(variables as Map),
        globalVariables: globalVariables,
      ));
    }

    try {
      if (req.method == 'GET') {
        if (await validateQuery(graphQlPostBody)(req, res) as bool) {
          return await executeMap(req.queryParameters);
        }
      } else if (req.method == 'POST') {
        if (req.headers.contentType?.mimeType == graphQlContentType.mimeType) {
          var text = await req.body.transform(utf8.decoder).join();
          return sendGraphQLResponse(await graphQL.parseAndExecute(
            text,
            sourceUrl: 'input',
            globalVariables: globalVariables,
          ));
        } else if (req.headers.contentType?.mimeType == 'application/json') {
          if (await validate(graphQlPostBody)(req, res) as bool) {
            return await executeMap(req.bodyAsMap);
          }
        } else if (req.headers.contentType?.mimeType == 'multipart/form-data') {
          var fields = await req.parseBody().then((_) => req.bodyAsMap);
          var operations = fields['operations'] as String;
          if (operations == null) {
            throw AngelHttpException.badRequest(
                message: 'Missing "operations" field.');
          }
          var map = fields.containsKey('map')
              ? json.decode(fields['map'] as String)
              : null;
          if (map is! Map) {
            throw AngelHttpException.badRequest(
                message: '"map" field must decode to a JSON object.');
          }
          var variables = Map<String, dynamic>.from(globalVariables);
          for (var entry in (map as Map).entries) {
            var file = req.uploadedFiles
                .firstWhere((f) => f.name == entry.key, orElse: () => null);
            if (file == null) {
              throw AngelHttpException.badRequest(
                  message:
                      '"map" contained key "${entry.key}", but no uploaded file '
                      'has that name.');
            }
            if (entry.value is! List) {
              throw AngelHttpException.badRequest(
                  message:
                      'The value for "${entry.key}" in the "map" field was not a JSON array.');
            }
            var objectPaths = entry.value as List;
            for (var objectPath in objectPaths) {
              var subPaths = (objectPath as String).split('.');
              if (subPaths[0] == 'variables') {
                Object current = variables;
                for (int i = 1; i < subPaths.length; i++) {
                  var name = subPaths[i];
                  var parent = subPaths.take(i).join('.');
                  if (_num.hasMatch(name)) {
                    if (current is! List) {
                      throw AngelHttpException.badRequest(
                          message:
                              'Object "$parent" is not a JSON array, but the '
                              '"map" field contained a mapping to $parent.$name.');
                    }
                    (current as List)[int.parse(name)] = file;
                  } else {
                    if (current is! Map) {
                      throw AngelHttpException.badRequest(
                          message:
                              'Object "$parent" is not a JSON object, but the '
                              '"map" field contained a mapping to $parent.$name.');
                    }
                    (current as Map)[name] = file;
                  }
                }
              } else {
                throw AngelHttpException.badRequest(
                    message:
                        'All array values in the "map" field must begin with "variables.".');
              }
            }
          }
          return await sendGraphQLResponse(await graphQL.parseAndExecute(
            operations,
            sourceUrl: 'input',
            globalVariables: variables,
          ));
        } else {
          throw AngelHttpException.badRequest();
        }
      } else {
        throw AngelHttpException.badRequest();
      }
    } on ValidationException catch (e) {
      var errors = <GraphQLExceptionError>[GraphQLExceptionError(e.message)];

      errors.addAll(e.errors.map((ee) => GraphQLExceptionError(ee)).toList());
      return GraphQLException(errors).toJson();
    } on AngelHttpException catch (e) {
      var errors = <GraphQLExceptionError>[GraphQLExceptionError(e.message)];

      errors.addAll(e.errors.map((ee) => GraphQLExceptionError(ee)).toList());
      return GraphQLException(errors).toJson();
    } on SyntaxError catch (e) {
      return GraphQLException.fromSourceSpan(e.message, e.span);
    } on GraphQLException catch (e) {
      return e.toJson();
    } catch (e, st) {
      if (req.app?.logger != null) {
        req.app.logger.severe(
            'An error occurred while processing GraphQL query at ${req.uri}.',
            e,
            st);
      }

      return GraphQLException.fromMessage(e.toString()).toJson();
    }
  };
}
