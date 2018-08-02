part of graphql_schema.src.schema;

class GraphQLFieldArgument<Value, Serialized> {
  final String name;
  final GraphQLType<Value, Serialized> type;
  final Value defaultValue;
  GraphQLFieldArgument(this.name, this.type, {this.defaultValue});
}
