part of graphql_schema.src.schema;

typedef FutureOr<Value> GraphQLFieldResolver<Value, Serialized>(
    Serialized serialized, Map<String, dynamic> argumentValues);

class GraphQLObjectField<Value, Serialized> {
  final List<GraphQLFieldInput> inputs = <GraphQLFieldInput>[];
  final String name;
  final GraphQLFieldResolver<Value, Serialized> resolve;
  final GraphQLType<Value, Serialized> type;
  final String description;
  final String deprecationReason;

  GraphQLObjectField(this.name, this.type,
      {Iterable<GraphQLFieldInput> arguments: const <GraphQLFieldInput>[],
      @required this.resolve,
      this.deprecationReason,
      this.description}) {
    assert(type != null, 'GraphQL fields must specify a `type`.');
    assert(
        resolve != null, 'GraphQL fields must specify a `resolve` callback.');
    this.inputs.addAll(arguments ?? <GraphQLFieldInput>[]);
  }

  bool get isDeprecated => deprecationReason?.isNotEmpty == true;

  FutureOr<Serialized> serialize(Value value) {
    return type.serialize(value);
  }

  FutureOr<Value> deserialize(Serialized serialized,
      [Map<String, dynamic> argumentValues = const <String, dynamic>{}]) {
    if (resolve != null) return resolve(serialized, argumentValues);
    return type.deserialize(serialized);
  }

  @override
  bool operator ==(other) =>
      other is GraphQLObjectField &&
      other.name == name &&
      other.deprecationReason == deprecationReason &&
      other.type == type &&
      other.resolve == resolve &&
      const ListEquality<GraphQLFieldInput>().equals(other.inputs, inputs);
}
