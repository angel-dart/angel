part of graphql_schema.src.schema;

typedef FutureOr<Value> GraphQLFieldResolver<Value, Serialized>(
    Serialized serialized);

class GraphQLField<Value, Serialized> {
  final String name;
  final GraphQLFieldArgument argument;
  final GraphQLFieldResolver<Value, Serialized> resolve;
  final GraphQLType<Value, Serialized> type;

  GraphQLField(this.name, {this.argument, this.resolve, this.type});

  FutureOr<Serialized> serialize(Value value) {
    return type.serialize(value);
  }

  FutureOr<Value> deserialize(Serialized serialized) {
    if (resolve != null) return resolve(serialized);
    return type.deserialize(serialized);
  }
}
