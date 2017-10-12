import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:mime/mime.dart';
import 'body_parse_result.dart';
import 'file_upload_info.dart';
import 'map_from_uri.dart';

/// Grabs data from an incoming request.
///
/// Supports URL-encoded and JSON, as well as multipart/* forms.
/// On a file upload request, only fields with the name **'file'** are processed
/// as files. Anything else is put in the body. You can change the upload file name
/// via the *fileUploadName* parameter. :)
///
/// Use [storeOriginalBuffer] to add  the original request bytes to the result.
Future<BodyParseResult> parseBody(HttpRequest request,
    {bool storeOriginalBuffer: false}) async {
  var result = new _BodyParseResultImpl();

  Future<List<int>> getBytes() {
    return request
        .fold<BytesBuilder>(new BytesBuilder(copy: false), (a, b) => a..add(b))
        .then((b) => b.takeBytes());
  }

  Future<String> getBody() {
    if (storeOriginalBuffer) {
      return getBytes().then((bytes) {
        result.originalBuffer = bytes;
        return UTF8.decode(bytes);
      });
    } else
      return request.transform(UTF8.decoder).join();
  }

  try {
    if (request.headers.contentType != null) {
      if (request.headers.contentType.primaryType == 'multipart' &&
          request.headers.contentType.parameters.containsKey('boundary')) {
        Stream<List<int>> stream;

        if (storeOriginalBuffer) {
          var bytes = result.originalBuffer = await getBytes();
          var ctrl = new StreamController<List<int>>()
            ..add(bytes)
            ..close();
          stream = ctrl.stream;
        } else {
          stream = request;
        }

        var parts = stream
            .transform(new MimeMultipartTransformer(
                request.headers.contentType.parameters['boundary']))
            .map((part) =>
                HttpMultipartFormData.parse(part, defaultEncoding: UTF8));

        await for (HttpMultipartFormData part in parts) {
          if (part.isBinary ||
              part.contentDisposition.parameters.containsKey("filename")) {
            BytesBuilder builder = await part.fold(
                new BytesBuilder(copy: false),
                (BytesBuilder b, d) => b..add(d is! String ? d : d.codeUnits));
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
      } else if (request.headers.contentType.mimeType ==
          ContentType.JSON.mimeType) {
        result.body.addAll(JSON.decode(await getBody()));
      } else if (request.headers.contentType.mimeType ==
          'application/x-www-form-urlencoded') {
        String body = await getBody();
        buildMapFromUri(result.body, body);
      } else if (storeOriginalBuffer == true) {
        result.originalBuffer = await getBytes();
      }
    } else {
      if (request.uri.hasQuery) {
        buildMapFromUri(result.query, request.uri.query);
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
