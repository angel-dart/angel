part of graphql_schema.src.schema;

GraphQLObjectType objectType(String name,
        [Iterable<GraphQLField> fields = const []]) =>
    new GraphQLObjectType(name)..fields.addAll(fields ?? []);

GraphQLField<T, Serialized> field<T, Serialized>(String name,
    {GraphQLFieldArgument<T, Serialized> argument,
    GraphQLFieldResolver<T, Serialized> resolve,
    GraphQLType<T, Serialized> type}) {
  return new GraphQLField(name,
      argument: argument, resolve: resolve, type: type);
}
