/// A library for parsing HTTP request bodies and queries.
library body_parser;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A representation of data from an incoming request.
class BodyParseResult {
  /// The parsed body.
  Map body = {};

  /// The parsed query string.
  Map query = {};

  /// All files uploaded within this request.
  List<Map> files = [];
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

  // Accept file
  if (contentType != null && request.method == 'POST') {
    RegExp parseBoundaryRgx = new RegExp(
        r'^multipart\/form-data;\s*boundary=(.+)$');
    if (parseBoundaryRgx.hasMatch(contentType.toString())) {
      Match boundaryMatch = parseBoundaryRgx.firstMatch(contentType.toString());
      String body = await request.transform(UTF8.decoder).join();
      for (String chunk in body.split(boundaryMatch.group(1))) {
        var fileData = getFileDataFromChunk(chunk);
        if (fileData != null)
          result.files.add(fileData);
      }
    }
  }

  return result;
}

/// Parses file data from a multipart/form-data chunk.
Map getFileDataFromChunk(String chunk) {
  Map result = {};
  RegExp isFormDataRgx = new RegExp(
      r'Content-Dispositition:\s*form-data;\s*name="([^"]+)"');

  if (isFormDataRgx.hasMatch(chunk)) {
    result['name'] = isFormDataRgx.firstMatch(chunk).group(1);

    RegExp contentTypeRgx = new RegExp(r'Content-Type:\s*([^\n]+)');
    if (contentTypeRgx.hasMatch(chunk)) {
      result['type'] = contentTypeRgx.firstMatch(chunk).group(1);
      return result;
    }
  }

  return null;
}

/// Parses a URI-encoded string into real data! **Wow!**
///
/// Whichever map you provide will be automatically populated from the urlencoded body string you provide.
buildMapFromUri(Map map, String body) {
  RegExp parseArrayRgx = new RegExp(r'^(.+)\[\]$');

  for (String keyValuePair in body.split('&')) {
    if (keyValuePair.contains('=')) {
      List<String> split = keyValuePair.split('=');
      String key = Uri.decodeQueryComponent(split[0]);
      String value = Uri.decodeQueryComponent(split[1]);

      if (parseArrayRgx.hasMatch(key)) {
        Match queryMatch = parseArrayRgx.firstMatch(key);
        key = queryMatch.group(1);
        if (!(map[key] is List)) {
          map[key] = [];
        }

        map[key].add(getValue(value));
      } else if (key.contains('.')) {
        // i.e. map.foo.bar => [map, foo, bar]
        List<String> keys = key.split('.');

        Map targetMap = map[keys[0]] ?? {};
        map[keys[0]] = targetMap;
        for (int i = 1; i < keys.length; i++) {
          if (i < keys.length - 1) {
            targetMap[keys[i]] = targetMap[keys[i]] ?? {};
            targetMap = targetMap[keys[i]];
          } else {
            targetMap[keys[i]] = getValue(value);
          }
        }
      }
      else map[key] = getValue(value);
    } else map[Uri.decodeQueryComponent(keyValuePair)] = true;
  }
}

getValue(String value) {
  num numValue = num.parse(value, (_) => double.NAN);
  if (!numValue.isNaN)
    return numValue;
  else if (value.startsWith('[') && value.endsWith(']'))
    return JSON.decode(value);
  else if (value.startsWith('{') && value.endsWith('}'))
    return JSON.decode(value);
  else if (value.trim().toLowerCase() == 'null')
    return null;
  else return value;
}