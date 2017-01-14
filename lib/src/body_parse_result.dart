import 'file_upload_info.dart';

/// A representation of data from an incoming request.
abstract class BodyParseResult {
  /// The parsed body.
  Map<String, dynamic> get body;

  /// The parsed query string.
  Map<String, dynamic> get query;

  /// All files uploaded within this request.
  List<FileUploadInfo> get files;

  /// The original body bytes sent with this request.
  /// 
  /// You must set [storeOriginalBuffer] to `true` to see this.
  List<int> get originalBuffer;
}
