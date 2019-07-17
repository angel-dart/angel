import 'generator.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection2/inflection2.dart';
import '../make/maker.dart';

class MongoServiceGenerator extends ServiceGenerator {
  const MongoServiceGenerator() : super('MongoDB');

  @override
  List<MakerDependency> get dependencies =>
      const [const MakerDependency('angel_mongo', '^2.0.0')];

  @override
  bool get createsModel => false;

  @override
  void applyToConfigureServer(
      LibraryBuilder library,
      MethodBuilder configureServer,
      BlockBuilder block,
      String name,
      String lower) {
    configureServer.requiredParameters.add(new Parameter((b) => b
      ..name = 'db'
      ..type = refer('Db')));
  }

  @override
  void applyToLibrary(LibraryBuilder library, String name, String lower) {
    library.directives.addAll([
      new Directive.import('package:angel_mongo/angel_mongo.dart'),
      new Directive.import('package:mongo_dart/mongo_dart.dart'),
    ]);
  }

  @override
  Expression createInstance(LibraryBuilder library, MethodBuilder methodBuilder,
      String name, String lower) {
    return refer('MongoService').newInstance([
      refer('db').property('collection').call([literal(pluralize(lower))])
    ]);
  }
}
