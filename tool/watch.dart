import 'package:build_runner/build_runner.dart';
import 'phases.dart';

main() => watch(phaseGroup, deleteFilesByDefault: true);
