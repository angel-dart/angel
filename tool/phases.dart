import 'package:build_runner/build_runner.dart';
import 'package:source_gen/builder.dart';
import 'package:source_gen/generators/json_serializable_generator.dart';

final PhaseGroup PHASES = new PhaseGroup.singleAction(
    new GeneratorBuilder(const [const JsonSerializableGenerator()]),
    new InputSet('angel', const [
      'bin/**/*.dart',
      'lib/**/*.dart',
      'views/**/*.dart',
      'web/**/*.dart'
    ]));
