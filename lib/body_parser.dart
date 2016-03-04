// A library for parsing HTTP request bodies and queries.

library body_parser;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:json_god/json_god.dart';

/// A representation of data from an incoming request.
class BodyParseResult {
  /// The parsed body.
  Map body = {};

  /// The parsed query string.
  Map query = {};
}

/// Grabs data from an incoming request.
///
/// Supports urlencoded and JSON.
Future<BodyParseResult> parseBody(HttpRequest request) async {
  BodyParseResult result = new BodyParseResult();
  ContentType contentType = request.headers.contentType;

  // Parse body
  if (contentType != null) {
    if (contentType.mimeType == 'application/json')
      result.body = JSON.decode(await request.transform(UTF8.decoder).join());
    else if (contentType.mimeType == 'application/x-www-form-urlencoded') {
      String body = await request.transform(UTF8.decoder).join();
      buildMapFromUri(result.body, body);
    }
  }

  // Parse query
  RegExp queryRgx = new RegExp(r'\?(.+)$');
  String uriString = request.requestedUri.toString();
  if (queryRgx.hasMatch(uriString)) {
    Match queryMatch = queryRgx.firstMatch(uriString);
    buildMapFromUri(result.query, queryMatch.group(1));
  }

  return result;
}

/// Parses a URI-encoded string into real data! **Wow!**
buildMapFromUri(Map map, String body) {
  God god = new God();
  for (String keyValuePair in body.split('&')) {
    if (keyValuePair.contains('=')) {
      List<String> split = keyValuePair.split('=');
      String key = Uri.decodeQueryComponent(split[0]);
      String value = Uri.decodeQueryComponent(split[1]);
      num numValue = num.parse(value, (_) => double.NAN);
      if (!numValue.isNaN)
        map[key] = numValue;
      else if (value.startsWith('[') && value.endsWith(']'))
        map[key] = god.deserialize(value);
      else if (value.startsWith('{') && value.endsWith('}'))
        map[key] = god.deserialize(value);
      else if (value.trim().toLowerCase() == 'null')
        map[key] = null;
      else map[key] = value;
    } else map[Uri.decodeQueryComponent(keyValuePair)] = true;
  }
}