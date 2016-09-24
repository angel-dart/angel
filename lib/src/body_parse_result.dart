import 'file_upload_info.dart';

/// A representation of data from an incoming request.
class BodyParseResult {
  /// The parsed body.
  Map body = {};

  /// The parsed query string.
  Map query = {};

  /// All files uploaded within this request.
  List<FileUploadInfo> files = [];
}
