part of graphql_schema.src.schema;

GraphQLObjectType objectType(String name,
        {String description,
        Iterable<GraphQLField> fields = const [],
        Iterable<GraphQLObjectType> interfaces = const []}) =>
    new GraphQLObjectType(name, description)
      ..fields.addAll(fields ?? [])
      ..interfaces.addAll(interfaces ?? []);

GraphQLField<T, Serialized> field<T, Serialized>(String name,
    {Iterable<GraphQLFieldArgument<T, Serialized>> arguments: const [],
    GraphQLFieldResolver<T, Serialized> resolve,
    GraphQLType<T, Serialized> type,
    String deprecationReason}) {
  return new GraphQLField(name,
      arguments: arguments,
      resolve: resolve,
      type: type,
      deprecationReason: deprecationReason);
}
