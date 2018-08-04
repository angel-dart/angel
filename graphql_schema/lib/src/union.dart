part of graphql_schema.src.schema;

class GraphQLUnionType<Value, Serialized> extends GraphQLType<Value, Serialized>
    with _NonNullableMixin<Value, Serialized> {
  final List<GraphQLType<Value, Serialized>> possibleTypes;
  final String description;

  GraphQLUnionType(this.possibleTypes, {this.description}) {
    assert(possibleTypes.every((t) => t is GraphQLUnionType),
        'The member types of a Union type must all be Object base types; Scalar, Interface and Union types may not be member types of a Union. Similarly, wrapping types may not be member types of a Union');
    assert(possibleTypes.isNotEmpty,
        'A Union type must define one or more member types');
  }

  @override
  String get name => possibleTypes.map((t) => t.name).join(' | ');

  @override
  Serialized serialize(Value value) {
    for (var type in possibleTypes) {
      try {
        return type.serialize(value);
      } catch (_) {}
    }

    throw new ArgumentError();
  }

  @override
  Value deserialize(Serialized serialized) {
    for (var type in possibleTypes) {
      try {
        return type.deserialize(serialized);
      } catch (_) {}
    }

    throw new ArgumentError();
  }

  @override
  ValidationResult<Serialized> validate(String key, Serialized input) {
    List<String> errors = [];

    for (var type in possibleTypes) {
      var result = type.validate(key, input);

      if (result.successful) {
        return result;
      } else {
        errors.addAll(result.errors);
      }
    }

    return new ValidationResult._failure(errors);
  }
}
