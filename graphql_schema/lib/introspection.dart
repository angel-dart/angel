import 'package:graphql_schema/graphql_schema.dart';

// TODO: How to handle custom types???
GraphQLSchema reflectSchema(GraphQLSchema schema) {
  var objectTypes = _fetchAllTypes(schema);
  var typeType = _reflectSchemaTypes(schema);

  var schemaType = objectType('__Schema', [
    field(
      'types',
      type: listType(typeType),
      resolve: (_, __) => objectTypes,
    ),
  ]);

  var fields = <GraphQLField>[
    field(
      '__schema',
      type: schemaType,
      resolve: (_, __) => schemaType,
    ),
    field(
      '__type',
      type: typeType,
      arguments: [
        new GraphQLFieldArgument('name', graphQLString.nonNullable())
      ],
      resolve: (_, args) {
        var name = args['name'] as String;
        return objectTypes.firstWhere((t) => t.name == name,
            orElse: () =>
                throw new GraphQLException('No type named "$name" exists.'));
      },
    ),
  ];

  fields.addAll(schema.query.fields);

  return new GraphQLSchema(
    query: objectType(schema.query.name, fields),
    mutation: schema.mutation,
  );
}

GraphQLObjectType _reflectSchemaTypes(GraphQLSchema schema) {
  var fieldType = _reflectFields();

  return objectType('__Type', [
    field(
      'name',
      type: graphQLString,
      resolve: (type, _) => (type as GraphQLObjectType).name,
    ),
    field(
      'kind',
      type: graphQLString,
      resolve: (type, _) => 'OBJECT', // TODO: Union, interface
    ),
    field(
      'fields',
      type: listType(fieldType),
      resolve: (type, _) => (type as GraphQLObjectType).fields,
    ),
  ]);
}

GraphQLObjectType _reflectFields() {
  return objectType('__Field', []);
}

List<GraphQLObjectType> _fetchAllTypes(GraphQLSchema schema) {
  var typess = <GraphQLType>[];
  typess.addAll(_fetchAllTypesFromObject(schema.query));

  if (schema.mutation != null) {
    typess.addAll(_fetchAllTypesFromObject(schema.mutation)
        .where((t) => t is GraphQLObjectType));
  }

  var types = <GraphQLObjectType>[];

  for (var type in typess) {
    if (type is GraphQLObjectType) types.add(type);
  }

  return types.toSet().toList();
}

List<GraphQLType> _fetchAllTypesFromObject(GraphQLObjectType objectType) {
  var types = <GraphQLType>[objectType];

  for (var field in objectType.fields) {
    if (field.type is GraphQLObjectType) {
      types.addAll(_fetchAllTypesFromObject(field.type as GraphQLObjectType));
    } else {
      types.addAll(_fetchAllTypesFromType(field.type));
    }
  }

  return types;
}

Iterable<GraphQLType> _fetchAllTypesFromType(GraphQLType type) {
  var types = <GraphQLType>[];

  if (type is GraphQLNonNullableType) {
    types.addAll(_fetchAllTypesFromType(type.innerType));
  } else if (type is GraphQLListType) {
    types.addAll(_fetchAllTypesFromType(type.innerType));
  } else if (type is GraphQLObjectType) {
    types.addAll(_fetchAllTypesFromObject(type));
  }

  // TODO: Enum, interface, union
  return types;
}
