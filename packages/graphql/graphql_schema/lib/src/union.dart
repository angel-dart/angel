part of graphql_schema.src.schema;

/// A special [GraphQLType] that indicates that an input value may be valid against one or more [possibleTypes].
///
/// All provided types must be [GraphQLObjectType]s.
class GraphQLUnionType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  /// The name of this type.
  final String name;

  /// A list of all types that conform to this union.
  final List<GraphQLObjectType> possibleTypes = [];

  GraphQLUnionType(
      this.name,
      Iterable<GraphQLType<Map<String, dynamic>, Map<String, dynamic>>>
          possibleTypes) {
    assert(possibleTypes.every((t) => t is GraphQLObjectType),
        'The member types of a Union type must all be Object base types; Scalar, Interface and Union types must not be member types of a Union. Similarly, wrapping types must not be member types of a Union.');
    assert(possibleTypes.isNotEmpty,
        'A Union type must define one or more member types.');

    for (var t in possibleTypes.toSet()) {
      this.possibleTypes.add(t as GraphQLObjectType);
    }
  }

  @override
  String get description => possibleTypes.map((t) => t.name).join(' | ');

  @override
  GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
      coerceToInputObject() {
    return new GraphQLUnionType(
        '${name}Input', possibleTypes.map((t) => t.coerceToInputObject()));
  }

  @override
  Map<String, dynamic> serialize(Map<String, dynamic> value) {
    for (var type in possibleTypes) {
      try {
        if (type.validate('@root', value).successful) {
          return type.serialize(value);
        }
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

  @override
  bool operator ==(other) =>
      other is GraphQLUnionType &&
      other.name == name &&
      other.description == description &&
      const ListEquality<GraphQLObjectType>()
          .equals(other.possibleTypes, possibleTypes);
}
