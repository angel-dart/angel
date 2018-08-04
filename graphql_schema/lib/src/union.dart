part of graphql_schema.src.schema;

class GraphQLUnionType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  final String name;
  final List<GraphQLObjectType> possibleTypes = [];

  GraphQLUnionType(
    this.name,
    Iterable<GraphQLObjectType> possibleTypes,
  ) {
    assert(possibleTypes.isNotEmpty,
        'A Union type must define one or more member types.');
    this.possibleTypes.addAll(possibleTypes.toSet());
  }

  @override
  String get description => possibleTypes.map((t) => t.name).join(' | ');

  @override
  Map<String, dynamic> serialize(Map<String, dynamic> value) {
    for (var type in possibleTypes) {
      try {
        return type.serialize(value);
      } catch (_) {}
    }

    throw new ArgumentError();
  }

  @override
  Map<String, dynamic> deserialize(Map<String, dynamic> serialized) {
    for (var type in possibleTypes) {
      try {
        return type.deserialize(serialized);
      } catch (_) {}
    }

    throw new ArgumentError();
  }

  @override
  ValidationResult<Map<String, dynamic>> validate(
      String key, Map<String, dynamic> input) {
    List<String> errors = [];

    for (var type in possibleTypes) {
      var result = type.validate(key, input);

      if (result.successful) {
        return result;
      } else {
        errors.addAll(result.errors);
      }
    }

    return new ValidationResult<Map<String, dynamic>>._failure(errors);
  }
}
