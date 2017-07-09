import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_orm/builder.dart';
import 'package:angel_serialize/builder.dart';

final InputSet MODELS = new InputSet('angel_orm', const ['test/models/*.dart']);

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
