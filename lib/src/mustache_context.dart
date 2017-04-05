import 'dart:io';
import 'package:path/path.dart' as path;

class MustacheContext {
  Directory viewDirectory;

  Directory partialDirectory;

  String extension;

  MustacheContext([this.viewDirectory, this.partialDirectory, this.extension]);

  File resolveView(String viewName) {
    return new File.fromUri(
        viewDirectory.uri.resolve('${viewName}${extension}'));
  }

  File resolvePartial(String partialName) {
    return new File.fromUri(
        partialDirectory.uri.resolve('${partialName}${extension}'));
  }
}
