part of graphql_schema.src.schema;

GraphQLObjectType objectType(String name,
        [Iterable<GraphQLField> fields = const []]) =>
    new GraphQLObjectType(name)..fields.addAll(fields ?? []);

GraphQLField<T, Serialized> field<T, Serialized>(String name,
    {Iterable<GraphQLFieldArgument<T, Serialized>> arguments: const [],
    GraphQLFieldResolver<T, Serialized> resolve,
    GraphQLType<T, Serialized> type}) {
  return new GraphQLField(name,
      arguments: arguments, resolve: resolve, type: type);
}
