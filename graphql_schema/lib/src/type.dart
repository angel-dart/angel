part of graphql_schema.src.schema;

abstract class GraphQLType<Value, Serialized> {
  Serialized serialize(Value value);
  Value deserialize(Serialized serialized);
  ValidationResult<Serialized> validate(String key, Serialized input);
  GraphQLType<Value, Serialized> nonNullable();
}

/// Shorthand to create a [GraphQLListType].
GraphQLListType<Value, Serialized> listType<Value, Serialized>(
        GraphQLType<Value, Serialized> innerType) =>
    new GraphQLListType<Value, Serialized>(innerType);

class GraphQLListType<Value, Serialized>
    extends GraphQLType<List<Value>, List<Serialized>>
    with _NonNullableMixin<List<Value>, List<Serialized>> {
  final GraphQLType<Value, Serialized> type;
  GraphQLListType(this.type);

  @override
  ValidationResult<List<Serialized>> validate(
      String key, List<Serialized> input) {
    if (input is! List)
      return new ValidationResult._failure(['Expected "$key" to be a list.']);

    List<Serialized> out = [];
    List<String> errors = [];

    for (int i = 0; i < input.length; i++) {
      var k = '"$key" at index $i';
      var v = input[i];
      var result = type.validate(k, v);
      if (!result.successful)
        errors.addAll(result.errors);
      else
        out.add(v);
    }

    if (errors.isNotEmpty) return new ValidationResult._failure(errors);
    return new ValidationResult._ok(out);
  }

  @override
  List<Value> deserialize(List<Serialized> serialized) {
    return serialized.map<Value>(type.deserialize).toList();
  }

  @override
  List<Serialized> serialize(List<Value> value) {
    return value.map<Serialized>(type.serialize).toList();
  }
}

abstract class _NonNullableMixin<Value, Serialized>
    implements GraphQLType<Value, Serialized> {
  GraphQLType<Value, Serialized> _nonNullableCache;
  GraphQLType<Value, Serialized> nonNullable() => _nonNullableCache ??=
      new _GraphQLNonNullableType<Value, Serialized>._(this);
}

class _GraphQLNonNullableType<Value, Serialized>
    extends GraphQLType<Value, Serialized> {
  final GraphQLType<Value, Serialized> type;
  _GraphQLNonNullableType._(this.type);

  @override
  GraphQLType<Value, Serialized> nonNullable() {
    throw new UnsupportedError(
        'Cannot call nonNullable() on a non-nullable type.');
  }

  @override
  ValidationResult<Serialized> validate(String key, Serialized input) {
    if (input == null)
      return new ValidationResult._failure(
          ['Expected "$key" to be a non-null value.']);
    return type.validate(key, input);
  }

  @override
  Value deserialize(Serialized serialized) {
    return type.deserialize(serialized);
  }

  @override
  Serialized serialize(Value value) {
    return type.serialize(value);
  }
}
