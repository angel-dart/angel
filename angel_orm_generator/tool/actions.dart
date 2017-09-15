import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_orm_generator/angel_orm_generator.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';

const String packageName = 'angel_orm_generator';
const List<String> allModels = const ['test/models/*.dart'];
const List<String> standaloneModels = const [
  'test/models/author.dart',
  'test/models/car.dart',
  'test/models/foot.dart',
  'test/models/fruit.dart',
  'test/models/role.dart'
];
const List<String> dependentModels = const [
  'test/models/book.dart',
  'test/models/leg.dart',
  'test/models/tree.dart',
  'test/models/user.dart'
];

final List<BuildAction> actions = [
  new BuildAction(
    new PartBuilder(const [const JsonModelGenerator()]),
    packageName,
    inputs: standaloneModels,
  ),
  new BuildAction(
    new PartBuilder(const [const JsonModelGenerator()]),
    packageName,
    inputs: dependentModels,
  ),
  new BuildAction(
    new LibraryBuilder(
      const PostgresOrmGenerator(),
      generatedExtension: '.orm.g.dart',
    ),
    packageName,
    inputs: standaloneModels,
  ),
  new BuildAction(
    new LibraryBuilder(
      const PostgresOrmGenerator(),
      generatedExtension: '.orm.g.dart',
    ),
    packageName,
    inputs: dependentModels,
  ),
  new BuildAction(
    new LibraryBuilder(
      const PostgresServiceGenerator(),
      generatedExtension: '.service.g.dart',
    ),
    packageName,
    inputs: allModels,
  ),
  new BuildAction(
    const SqlMigrationBuilder(
      temporary: true,
    ),
    packageName,
    inputs: allModels,
  ),
];
