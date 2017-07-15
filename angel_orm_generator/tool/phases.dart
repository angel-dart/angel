import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_orm_generator/angel_orm_generator.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';

final InputSet ALL_MODELS =
    new InputSet('angel_orm_generator', const ['test/models/*.dart']);
final InputSet STANDALONE_MODELS = new InputSet('angel_orm_generator', const [
  'test/models/car.dart',
  'test/models/author.dart',
  'test/models/role.dart'
]);
final InputSet DEPENDENT_MODELS = new InputSet('angel_orm_generator',
    const ['test/models/book.dart', 'test/models/user.dart']);

final PhaseGroup PHASES = new PhaseGroup()
  ..addPhase(new Phase()
    ..addAction(
        new GeneratorBuilder([const JsonModelGenerator()]), STANDALONE_MODELS)
    ..addAction(
        new GeneratorBuilder([const JsonModelGenerator()]), DEPENDENT_MODELS))
  ..addPhase(new Phase()
    ..addAction(
        new GeneratorBuilder([new PostgresORMGenerator()],
            isStandalone: true, generatedExtension: '.orm.g.dart'),
        STANDALONE_MODELS))
  ..addPhase(new Phase()
    ..addAction(
        new GeneratorBuilder([new PostgresORMGenerator()],
            isStandalone: true, generatedExtension: '.orm.g.dart'),
        DEPENDENT_MODELS))
  ..addPhase(new Phase()
    ..addAction(new SQLMigrationGenerator(temporary: true), ALL_MODELS));
