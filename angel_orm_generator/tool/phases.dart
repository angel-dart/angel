import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_orm_generator/angel_orm_generator.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';

final InputSet MODELS =
    new InputSet('angel_orm_generator', const ['test/models/*.dart']);

final PhaseGroup PHASES = new PhaseGroup()
  ..addPhase(new Phase()
    ..addAction(new GeneratorBuilder([const JsonModelGenerator()]), MODELS))
  ..addPhase(new Phase()
    ..addAction(
        new GeneratorBuilder([new PostgresORMGenerator()],
            isStandalone: true, generatedExtension: '.orm.g.dart'),
        MODELS))
  ..addPhase(new Phase()
    ..addAction(new SQLMigrationGenerator(temporary: true), MODELS));
