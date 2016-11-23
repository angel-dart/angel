import 'package:test/test.dart';
import 'no_params.dart' as no_params;
import 'parse_params.dart' as parse_params;
import 'with_params.dart' as with_params;

main() {
  group('parse params', parse_params.main);
  group('no params', no_params.main);
  group('with params', with_params.main);
}