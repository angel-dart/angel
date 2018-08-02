part of graphql_schema.src.schema;

typedef FutureOr<Value> GraphQLFieldResolver<Value, Serialized>(
    Serialized serialized);

class GraphQLField<Value, Serialized> {
  final List<GraphQLFieldArgument> arguments = <GraphQLFieldArgument>[];
  final String name;
  final GraphQLFieldResolver<Value, Serialized> resolve;
  final GraphQLType<Value, Serialized> type;

  GraphQLField(this.name,
      {Iterable<GraphQLFieldArgument> arguments: const <GraphQLFieldArgument>[],
      this.resolve,
      this.type}) {
    this.arguments.addAll(arguments ?? <GraphQLFieldArgument>[]);
  }

  FutureOr<Serialized> serialize(Value value) {
    return type.serialize(value);
  }

  FutureOr<Value> deserialize(Serialized serialized) {
    if (resolve != null) return resolve(serialized);
    return type.deserialize(serialized);
  }
}
