part of graphql_schema.src.schema;

class GraphQLFieldArgument<Value, Serialized> {
  final String name;
  final GraphQLType<Value, Serialized> type;
  final Value defaultValue;
  final String description;

  /// If [defaultValue] is `null`, and `null` is a valid value for this argument, set this to `true`.
  final bool defaultsToNull;

  GraphQLFieldArgument(this.name, this.type,
      {this.defaultValue, this.defaultsToNull: false, this.description});
}
