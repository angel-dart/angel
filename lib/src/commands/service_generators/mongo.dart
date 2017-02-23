import 'generator.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection/inflection.dart';

class MongoServiceGenerator extends ServiceGenerator {
  const MongoServiceGenerator() : super('MongoDB');

  @override
  void applyToConfigureServer(
      MethodBuilder configureServer, String name, String lower) {
    configureServer.addPositional(parameter('db', [new TypeBuilder('Db')]));
  }

  @override
  void applyToLibrary(LibraryBuilder library, String name, String lower) {
    library.addMembers([
      'package:angel_mongo/angel_mongo.dart',
      'package:mongo_dart/mongo_dart.dart'
    ].map((str) => new ImportBuilder(str)));
  }

  @override
  ExpressionBuilder createInstance(
      MethodBuilder methodBuilder, String name, String lower) {
    return new TypeBuilder('MongoService').newInstance([
      reference('db').invoke('collection', [literal(pluralize(lower))])
    ]);
  }
}
