import 'package:build_runner/build_runner.dart';
import 'actions.dart';

main() => watch(actions, deleteFilesByDefault: true);
