import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart2_constant/convert.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http_server/http_server.dart';
import 'package:mime/mime.dart';

import 'body_parse_result.dart';
import 'file_upload_info.dart';
import 'map_from_uri.dart';

/// Forwards to [parseBodyFromStream].
@deprecated
Future<BodyParseResult> parseBody(HttpRequest request,
    {bool storeOriginalBuffer: false}) {
  return parseBodyFromStream(
      request,
      request.headers.contentType != null
          ? new MediaType.parse(request.headers.contentType.toString())
          : null,
      request.uri,
      storeOriginalBuffer: storeOriginalBuffer);
}

/// Grabs data from an incoming request.
///
/// Supports URL-encoded and JSON, as well as multipart/* forms.
/// On a file upload request, only fields with the name **'file'** are processed
/// as files. Anything else is put in the body. You can change the upload file name
/// via the *fileUploadName* parameter. :)
///
/// Use [storeOriginalBuffer] to add  the original request bytes to the result.
Future<BodyParseResult> parseBodyFromStream(
    Stream<Uint8List> data, MediaType contentType, Uri requestUri,
    {bool storeOriginalBuffer: false}) async {
  var result = new _BodyParseResultImpl();

  Future<Uint8List> getBytes() {
    return data
        .fold<BytesBuilder>(new BytesBuilder(copy: false), (a, b) => a..add(b))
        .then((b) => b.takeBytes());
  }

  Future<String> getBody() {
    if (storeOriginalBuffer) {
      return getBytes().then((bytes) {
        result.originalBuffer = bytes;
        return utf8.decode(bytes);
      });
    } else {
      return utf8.decoder.bind(data).join();
    }
  }

  try {
    if (contentType != null) {
      if (contentType.type == 'multipart' &&
          contentType.parameters.containsKey('boundary')) {
        Stream<Uint8List> stream;

        if (storeOriginalBuffer) {
          var bytes = result.originalBuffer = await getBytes();
          var ctrl = new StreamController<Uint8List>()
            ..add(bytes)
            ..close();
          stream = ctrl.stream;
        } else {
          stream = data;
        }

        var parts = MimeMultipartTransformer(
            contentType.parameters['boundary']).bind(stream)
            .map((part) =>
                HttpMultipartFormData.parse(part, defaultEncoding: utf8));

        await for (HttpMultipartFormData part in parts) {
          if (part.isBinary ||
              part.contentDisposition.parameters.containsKey("filename")) {
            BytesBuilder builder = await part.fold(
                new BytesBuilder(copy: false),
                (BytesBuilder b, d) => b
                  ..add(d is! String
                      ? (d as List<int>)
                      : (d as String).codeUnits));
            var upload = new FileUploadInfo(
                mimeType: part.contentType.mimeType,
                name: part.contentDisposition.parameters['name'],
                filename:
                    part.contentDisposition.parameters['filename'] ?? 'file',
                data: builder.takeBytes());
            result.files.add(upload);
          } else if (part.isText) {
            var text = await part.join();
            buildMapFromUri(result.body,
                '${part.contentDisposition.parameters["name"]}=$text');
          }
        }
      } else if (contentType.mimeType == 'application/json') {
        result.body
            .addAll(_foldToStringDynamic(json.decode(await getBody()) as Map));
      } else if (contentType.mimeType == 'application/x-www-form-urlencoded') {
        String body = await getBody();
        buildMapFromUri(result.body, body);
      } else if (storeOriginalBuffer == true) {
        result.originalBuffer = await getBytes();
      }
    } else {
      if (requestUri.hasQuery) {
        buildMapFromUri(result.query, requestUri.query);
      }

      if (storeOriginalBuffer == true) {
        result.originalBuffer = await getBytes();
      }
    }
  } catch (e, st) {
    result.error = e;
    result.stack = st;
  }

  return result;
}

class _BodyParseResultImpl implements BodyParseResult {
  @override
  Map<String, dynamic> body = {};

  @override
  List<FileUploadInfo> files = [];

  @override
  List<int> originalBuffer;

  @override
  Map<String, dynamic> query = {};

  @override
  var error = null;

  @override
  StackTrace stack = null;
}

Map<String, dynamic> _foldToStringDynamic(Map map) {
  return map == null
      ? null
      : map.keys.fold<Map<String, dynamic>>(
          <String, dynamic>{}, (out, k) => out..[k.toString()] = map[k]);
}
