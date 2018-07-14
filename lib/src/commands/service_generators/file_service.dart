import 'generator.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection/inflection.dart';
import '../make/maker.dart';

class FileServiceGenerator extends ServiceGenerator {
  const FileServiceGenerator() : super('Persistent JSON File');

  @override
  List<MakerDependency> get dependencies =>
      const [const MakerDependency('angel_file_service', '^1.0.0')];

  @override
  bool get goesFirst => true;

  @override
  void applyToConfigureServer(MethodBuilder configureServer, BlockBuilder block,
      String name, String lower) {
    configureServer.requiredParameters.add(new Parameter((b) => b
      ..name = 'dbDirectory'
      ..type = refer('Directory')));
  }

  @override
  void applyToLibrary(LibraryBuilder library, String name, String lower) {
    library.directives.addAll([
      new Directive.import(
          'package:angel_file_service/angel_file_service.dart'),
      new Directive.import('package:file/file.dart'),
    ]);
  }

  @override
  Expression createInstance(
      MethodBuilder methodBuilder, String name, String lower) {
    return refer('JsonFileService').newInstance([
      refer('dbDirectory')
          .property('childFile')
          .call([literal(pluralize(lower) + '_db.json')])
    ]);
  }
}
