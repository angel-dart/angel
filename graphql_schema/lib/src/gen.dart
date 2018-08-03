part of graphql_schema.src.schema;

GraphQLObjectType objectType(String name,
    {String description,
    bool isInterface: false,
    Iterable<GraphQLField> fields = const [],
    Iterable<GraphQLObjectType> interfaces = const []}) {
  var obj = new GraphQLObjectType(name, description, isInterface: isInterface)
    ..fields.addAll(fields ?? []);

  if (interfaces?.isNotEmpty == true) {
    for (var i in interfaces) {
      obj.inheritFrom(i);
    }
  }

  return obj;
}

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
