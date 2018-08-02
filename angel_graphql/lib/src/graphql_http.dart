import 'dart:io';

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/server.dart';
import 'package:dart2_constant/convert.dart';
import 'package:graphql_server/graphql_server.dart';

final ContentType graphQlContentType =
    new ContentType('application', 'graphql');

final Validator graphQlPostBody = new Validator({
  'query*': isNonEmptyString,
  'operation_name': isNonEmptyString,
  'variables': predicate((v) => v == null || v is Map),
});

Map<String, dynamic> _foldToStringDynamic(Map map) {
  return map == null
      ? null
      : map.keys.fold<Map<String, dynamic>>(
          <String, dynamic>{}, (out, k) => out..[k.toString()] = map[k]);
}

RequestHandler graphQLHttp(GraphQL graphQl) {
  return (req, res) async {
    if (req.headers.contentType?.mimeType == graphQlContentType.mimeType) {
      var text = utf8.decode(await req.lazyOriginalBuffer());
      return {'data': await graphQl.parseAndExecute(text, sourceUrl: 'input')};
    } else if (req.headers.contentType?.mimeType == 'application/json') {
      if (await validate(graphQlPostBody)(req, res)) {
        var text = req.body['query'] as String;
        var operationName = req.body['operation_name'] as String;
        var variables = req.body['variables'] as Map;
        return {
          'data': await graphQl.parseAndExecute(
            text,
            sourceUrl: 'input',
            operationName: operationName,
            variableValues: _foldToStringDynamic(variables),
          ),
        };
      }
    } else {
      throw new AngelHttpException.badRequest();
    }
  };
}
