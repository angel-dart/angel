import 'generator.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection/inflection.dart';

class FileServiceGenerator extends ServiceGenerator {
  const FileServiceGenerator() : super('Persistent JSON File');

  @override
  bool get createsModel => false;

  @override
  void applyToLibrary(LibraryBuilder library, String name, String lower) {
    library.addMember(new ImportBuilder('dart:io'));
    library.addMember(new ImportBuilder(
        'package:angel_file_service/angel_file_service.dart'));
  }

  @override
  ExpressionBuilder createInstance(
      MethodBuilder methodBuilder, String name, String lower) {
    return new TypeBuilder('JsonFileService').newInstance([
      new TypeBuilder('File')
          .newInstance([literal(pluralize(lower) + '_db.json')])
    ]);
  }
}
