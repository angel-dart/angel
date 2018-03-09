import 'package:build_runner/build_runner.dart';
import 'applications.dart';

main() => watch(applications, deleteFilesByDefault: true, verbose: false);
