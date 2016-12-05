import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:mime/mime.dart';
import 'body_parse_result.dart';
import 'chunk.dart';
import 'file_upload_info.dart';
import 'map_from_uri.dart';

/// Grabs data from an incoming request.
///
/// Supports URL-encoded and JSON, as well as multipart/* forms.
/// On a file upload request, only fields with the name **'file'** are processed
/// as files. Anything else is put in the body. You can change the upload file name
/// via the *fileUploadName* parameter. :)
Future<BodyParseResult> parseBody(HttpRequest request) async {
  var result = new BodyParseResult();

  try {
    if (request.headers.contentType != null) {
      if (request.headers.contentType.primaryType == 'multipart' &&
          request.headers.contentType.parameters.containsKey('boundary')) {
        var parts = request
            .transform(new MimeMultipartTransformer(
                request.headers.contentType.parameters['boundary']))
            .map((part) =>
                HttpMultipartFormData.parse(part, defaultEncoding: UTF8));

        await for (HttpMultipartFormData part in parts) {
          if (part.isBinary ||
              part.contentDisposition.parameters.containsKey("filename")) {
            BytesBuilder builder = await part.fold(new BytesBuilder(),
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
        result.body
            .addAll(JSON.decode(await request.transform(UTF8.decoder).join()));
      } else if (request.headers.contentType.mimeType ==
          'application/x-www-form-urlencoded') {
        String body = await request.transform(UTF8.decoder).join();
        buildMapFromUri(result.body, body);
      }
    } else if (request.uri.hasQuery) {
      buildMapFromUri(result.query, request.uri.query);
    }
  } catch (e) {
    //
  }

  return result;
}
