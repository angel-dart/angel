/// A library for parsing HTTP request bodies and queries.
library body_parser;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

part 'file_upload_info.dart';

/// A representation of data from an incoming request.
class BodyParseResult {
  /// The parsed body.
  Map body = {};

  /// The parsed query string.
  Map query = {};

  /// All files uploaded within this request.
  List<FileUploadInfo> files = [];
}

/// Grabs data from an incoming request.
///
/// Supports urlencoded and JSON, as well as multipart/form-data uploads.
/// On a file upload request, only fields with the name **'file'** are processed
/// as files. Anything else is put in the body. You can change the upload file name
/// via the *fileUploadName* parameter. :)
Future<BodyParseResult> parseBody(HttpRequest request,
    {String fileUploadName: 'file'}) async {
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
        r'multipart\/form-data;\s*boundary=([^\s;]+)');
    if (parseBoundaryRgx.hasMatch(contentType.toString())) {
      Match boundaryMatch = parseBoundaryRgx.firstMatch(contentType.toString());
      String boundary = boundaryMatch.group(1);
      String body = await request.transform(UTF8.decoder).join();
      for (String chunk in body.split(boundary)) {
        var fileData = getFileDataFromChunk(
            chunk, boundary, fileUploadName, result.body);
        if (fileData != null)
          fileData.forEach((x) => result.files.add(x));
      }
    }
  }

  return result;
}

/// Parses file data from a multipart/form-data chunk.
List<FileUploadInfo> getFileDataFromChunk(String chunk, String boundary, String fileUploadName,
    Map body) {
  FileUploadInfo result = new FileUploadInfo();
  RegExp isFormDataRgx = new RegExp(
      r'Content-Disposition:\s*([^;]+);\s*name="([^"]+)"');

  if (isFormDataRgx.hasMatch(chunk)) {
    Match formDataMatch = isFormDataRgx.firstMatch(chunk);
    String disposition = formDataMatch.group(1);
    String name = formDataMatch.group(2);
    String restOfChunk = chunk.substring(formDataMatch.end);

    RegExp parseFilenameRgx = new RegExp(r'filename="([^"]+)"');
    if (parseFilenameRgx.hasMatch(chunk)) {
      result.filename = parseFilenameRgx.firstMatch(chunk).group(1);
    }

    RegExp contentTypeRgx = new RegExp(r'Content-Type:\s*([^\r\n]+)\r\n');
    if (contentTypeRgx.hasMatch(restOfChunk)) {
      Match contentTypeMatch = contentTypeRgx.firstMatch(restOfChunk);
      restOfChunk = restOfChunk.substring(contentTypeMatch.end);
      result.mimeType = contentTypeMatch.group(1);
    } else restOfChunk = restOfChunk.replaceAll(new RegExp(r'^(\r\n)+'), "");

    restOfChunk = restOfChunk
        .replaceAll(boundary, "")
        .replaceFirst(new RegExp(r'\r\n$'), "");

    if (disposition == 'file' && name == fileUploadName) {
      result.name = name;
      result.data = UTF8.encode(restOfChunk);
      return [result];
    } else {
      buildMapFromUri(body, "$name=$restOfChunk");
      return null;
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