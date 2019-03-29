part of graphql_schema.src.schema;

/// Shorthand for building a [GraphQLEnumType].
GraphQLEnumType enumType<Value>(String name, Map<String, Value> values,
    {String description}) {
  return new GraphQLEnumType<Value>(
      name, values.keys.map((k) => new GraphQLEnumValue(k, values[k])).toList(),
      description: description);
}

/// Shorthand for building a [GraphQLEnumType] where all the possible values
/// are mapped to Dart strings.
GraphQLEnumType<String> enumTypeFromStrings(String name, List<String> values,
    {String description}) {
  return new GraphQLEnumType<String>(
      name, values.map((s) => new GraphQLEnumValue(s, s)).toList(),
      description: description);
}

/// A [GraphQLType] with only a predetermined number of possible values.
///
/// Though these are serialized as strings, they carry special meaning with a type system.
class GraphQLEnumType<Value> extends GraphQLScalarType<Value, String>
    with _NonNullableMixin<Value, String> {
  /// The name of this enum type.
  final String name;

  /// The defined set of possible values for this type.
  ///
  /// No other values will be accepted than the ones you define.
  final List<GraphQLEnumValue<Value>> values;

  /// A description of this enum type, for tools like GraphiQL.
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

/// A known value of a [GraphQLEnumType].
///
/// In practice, you might not directly call this constructor very often.
class GraphQLEnumValue<Value> {
  /// The name of this value.
  final String name;

  /// The Dart value associated with enum values bearing the given [name].
  final Value value;

  /// An optional description of this value; useful for tools like GraphiQL.
  final String description;

  /// The reason, if any, that this value was deprecated, if it indeed is deprecated.
  final String deprecationReason;

  GraphQLEnumValue(this.name, this.value,
      {this.description, this.deprecationReason});

  /// Returns `true` if this value has a [deprecationReason].
  bool get isDeprecated => deprecationReason != null;

  @override
  bool operator ==(other) =>
      other is GraphQLEnumValue &&
      other.name == name &&
      other.value == value &&
      other.description == description &&
      other.deprecationReason == deprecationReason;
}
