import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:graphql_schema/graphql_schema.dart';
part 'starship.g.dart';

@serializable
@graphQLClass
abstract class _Starship extends Model {
  String get name;
  int get length;
}
