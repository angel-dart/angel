import 'package:file/file.dart';
import 'package:path/path.dart' as path;

class MustacheContext {
  Directory viewDirectory;

  Directory partialDirectory;

  String extension;

  MustacheContext([this.viewDirectory, this.partialDirectory, this.extension]);

  File resolveView(String viewName) {
    return viewDirectory.childFile('${viewName}${extension}');
  }

  File resolvePartial(String partialName) {
    return partialDirectory.childFile('${partialName}${extension}');
  }
}
