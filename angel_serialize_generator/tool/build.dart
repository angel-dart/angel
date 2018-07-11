import 'package:build_runner/build_runner.dart';
import 'applications.dart';

main() => build(applications, deleteFilesByDefault: true, verbose: false);
