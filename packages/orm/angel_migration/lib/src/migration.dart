import 'schema.dart';

abstract class Migration {
  void up(Schema schema);
  void down(Schema schema);
}
