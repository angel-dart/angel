import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';

final PhaseGroup PHASES = new PhaseGroup.singleAction(
    new PartBuilder([const JsonModelGenerator()]),
    new InputSet('angel_serialize_generator', const ['test/models/*.dart']));
