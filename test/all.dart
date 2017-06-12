import 'package:test/test.dart';
import 'embed_shelf_test.dart' as embed_shelf;
import 'support_shelf_test.dart' as support_shelf;

main() {
  group('embed_shelf', embed_shelf.main);
  group('support_shelf', support_shelf.main);
}