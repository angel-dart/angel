import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_serialize/builder.dart';

final PhaseGroup PHASES = new PhaseGroup.singleAction(
    new GeneratorBuilder([const JsonModelGenerator()]),
    new InputSet('angel_serialize', const ['test/models/*.dart']));
