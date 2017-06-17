import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_orm/builder.dart';
import 'package:angel_serialize/builder.dart';

final PhaseGroup PHASES = new PhaseGroup()
  ..addPhase(new Phase()
    ..addAction(new GeneratorBuilder([const JsonModelGenerator()]),
        new InputSet('angel_orm', const ['test/models/*.dart'])))
  ..addPhase(new Phase()
    ..addAction(
        new GeneratorBuilder([new AngelQueryBuilderGenerator.postgresql()],
            isStandalone: true, generatedExtension: '.orm.g.dart'),
        new InputSet('angel_orm', const ['test/models/*.dart'])));
