import 'package:build_runner/build_runner.dart';
import 'package:check_for_update/builder.dart';

final PhaseGroup phaseGroup = new PhaseGroup.singleAction(
    new CheckForUpdateBuilder(subDirectory: 'lib/src'),
    new InputSet('angel_cli', const ['pubspec.yaml']));
