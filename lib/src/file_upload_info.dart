/// Represents a file uploaded to the server.
class FileUploadInfo {
  /// The MIME type of the uploaded file.
  String mimeType;

  /// The name of the file field from the request.
  String name;

  /// The filename of the file.
  String filename;

  /// The bytes that make up this file.
  List<int> data;

  FileUploadInfo(
      {this.mimeType, this.name, this.filename, this.data: const []}) {}
}
