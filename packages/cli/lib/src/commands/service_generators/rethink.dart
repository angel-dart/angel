import 'generator.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection2/inflection2.dart';
import '../make/maker.dart';

class RethinkServiceGenerator extends ServiceGenerator {
  const RethinkServiceGenerator() : super('RethinkDB');

  @override
  List<MakerDependency> get dependencies =>
      const [const MakerDependency('angel_rethink', '^2.0.0')];

  @override
  bool get createsModel => false;

  @override
  void applyToConfigureServer(
      LibraryBuilder library,
      MethodBuilder configureServer,
      BlockBuilder block,
      String name,
      String lower) {
    configureServer.requiredParameters.addAll([
      new Parameter((b) => b
        ..name = 'connection'
        ..type = refer('Connection')),
      new Parameter((b) => b
        ..name = 'r'
        ..type = refer('Rethinkdb')),
    ]);
  }

  @override
  void applyToLibrary(LibraryBuilder library, String name, String lower) {
    library.directives.addAll([
      'package:angel_rethink/angel_rethink.dart',
      'package:rethinkdb_driver/rethinkdb_driver.dart'
    ].map((str) => new Directive.import(str)));
  }

  @override
  Expression createInstance(LibraryBuilder library, MethodBuilder methodBuilder,
      String name, String lower) {
    return refer('RethinkService').newInstance([
      refer('connection'),
      refer('r').property('table').call([literal(pluralize(lower))])
    ]);
  }
}
