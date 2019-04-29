import 'package:angel_serialize/angel_serialize.dart';
import 'package:graphql_schema/graphql_schema.dart';
part 'todo.g.dart';

@graphQLClass
@serializable
abstract class _Todo extends Model {
  String get text;

  bool get isComplete;
}
