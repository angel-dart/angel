part of graphql_schema.src.schema;

GraphQLEnumType enumType<Value>(String name, Map<String, Value> values,
    {String description}) {
  return new GraphQLEnumType<Value>(
      name, values.keys.map((k) => new GraphQLEnumValue(k, values[k])).toList(),
      description: description);
}

GraphQLEnumType enumTypeFromStrings(String name, List<String> values,
    {String description}) {
  return new GraphQLEnumType<String>(
      name, values.map((s) => new GraphQLEnumValue(s, s)).toList(),
      description: description);
}

class GraphQLEnumType<Value> extends GraphQLScalarType<Value, String>
    with _NonNullableMixin<Value, String> {
  final String name;
  final List<GraphQLEnumValue<Value>> values;
  final String description;

  GraphQLEnumType(this.name, this.values, {this.description});

  @override
  String serialize(Value value) {
    if (value == null) return null;
    return values.firstWhere((v) => v.value == value).name;
  }

  @override
  Value deserialize(String serialized) {
    return values.firstWhere((v) => v.name == serialized).value;
  }

  @override
  ValidationResult<String> validate(String key, String input) {
    if (!values.any((v) => v.name == input)) {
      if (input == null) {
        return new ValidationResult<String>._failure(
            ['The enum "$name" does not accept null values.']);
      }

      return new ValidationResult<String>._failure(
          ['"$input" is not a valid value for the enum "$name".']);
    }

    return new ValidationResult<String>._ok(input);
  }

  @override
  bool operator ==(other) =>
      other is GraphQLEnumType &&
      other.name == name &&
      other.description == description &&
      const ListEquality<GraphQLEnumValue>().equals(other.values, values);

  @override
  GraphQLType<Value, String> coerceToInputObject() => this;
}

class GraphQLEnumValue<Value> {
  final String name;
  final Value value;
  final String description;
  final String deprecationReason;

  GraphQLEnumValue(this.name, this.value,
      {this.description, this.deprecationReason});

  bool get isDeprecated => deprecationReason != null;

  @override
  bool operator ==(other) =>
      other is GraphQLEnumValue &&
      other.name == name &&
      other.value == value &&
      other.description == description &&
      other.deprecationReason == deprecationReason;
}
