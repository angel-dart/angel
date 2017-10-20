import 'generator.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection/inflection.dart';
import '../make/maker.dart';

class MongoServiceGenerator extends ServiceGenerator {
  const MongoServiceGenerator() : super('MongoDB');

  @override
  List<MakerDependency> get dependencies =>
      const [const MakerDependency('angel_mongo', '^1.0.0')];

  @override
  bool get createsModel => false;

  @override
  void applyToConfigureServer(
      MethodBuilder configureServer, String name, String lower) {
    configureServer.addPositional(parameter('db', [new TypeBuilder('Db')]));
  }

  @override
  void applyToLibrary(LibraryBuilder library, String name, String lower) {
    library.addMembers([
      new ImportBuilder('package:angel_mongo/angel_mongo.dart'),
      new ImportBuilder('package:mongo_dart/mongo_dart.dart'),
    ]);
  }

  @override
  ExpressionBuilder createInstance(
      MethodBuilder methodBuilder, String name, String lower) {
    return new TypeBuilder('MongoService').newInstance([
      reference('db').invoke('collection', [literal(pluralize(lower))])
    ]);
  }
}
