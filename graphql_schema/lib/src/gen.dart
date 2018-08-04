part of graphql_schema.src.schema;

GraphQLObjectType objectType(String name,
    {String description,
    bool isInterface: false,
    Iterable<GraphQLObjectField> fields = const [],
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

GraphQLObjectField<T, Serialized> field<T, Serialized>(
    String name, GraphQLType<T, Serialized> type,
    {Iterable<GraphQLFieldInput<T, Serialized>> inputs: const [],
    GraphQLFieldResolver<T, Serialized> resolve,
    String deprecationReason, String description}) {
  return new GraphQLObjectField<T, Serialized>(name, type,
      arguments: inputs,
      resolve: resolve ?? (_, __) => null,
      description: description,
      deprecationReason: deprecationReason);
}

GraphQLInputObjectType inputObjectType(String name,
    {String description,
    Iterable<GraphQLInputObjectField> inputFields: const []}) {
  return new GraphQLInputObjectType(name,
      description: description, inputFields: inputFields);
}

GraphQLInputObjectField<T, Serialized> inputField<T, Serialized>(
    String name, GraphQLType<T, Serialized> type,
    {String description, T defaultValue}) {
  return new GraphQLInputObjectField(name, type,
      description: description, defaultValue: defaultValue);
}
