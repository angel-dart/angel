import 'dart:async';
import 'file_info.dart';

/// A class capable of transforming inputs into new outputs, on-the-fly.
///
/// Ex. A transformer that compiles Stylus files.
abstract class FileTransformer {
  /// Changes the name of a [file] into what it will be once it is transformed.
  ///
  /// If this transformer will not be consume the file, then return `null`.
  FileInfo declareOutput(FileInfo file);

  /// Transforms an input [file] into a new representation.
  FutureOr<FileInfo> transform(FileInfo file);
}