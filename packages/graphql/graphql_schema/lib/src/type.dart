part of graphql_schema.src.schema;

/// Strictly dictates the structure of some input data in a GraphQL query.
///
/// GraphQL's rigid type system is primarily implemented in Dart using classes that extend from [GraphQLType].
///
/// A [GraphQLType] represents values of type [Value] as values of type [Serialized]; for example, a
/// [GraphQLType] that serializes objects into `String`s.
abstract class GraphQLType<Value, Serialized> {
  /// The name of this type.
  String get name;

  /// A description of this type, which, while optional, can be very useful in tools like GraphiQL.
  String get description;

  /// Serializes an arbitrary input value.
  Serialized serialize(Value value);

  /// Deserializes a serialized value.
  Value deserialize(Serialized serialized);

  /// Attempts to cast a dynamic [value] into a [Serialized] instance.
  Serialized convert(value) => value as Serialized;

  /// Performs type coercion against an [input] value, and returns a list of errors if the validation was unsuccessful.
  ValidationResult<Serialized> validate(String key, Serialized input);

  /// Creates a non-nullable type that represents this type, and enforces that a field of this type is present in input data.
  GraphQLType<Value, Serialized> nonNullable();

  /// Turns this type into one suitable for being provided as an input to a [GraphQLObjectField].
  GraphQLType<Value, Serialized> coerceToInputObject();

  @override
  String toString() => name;
}

/// Shorthand to create a [GraphQLListType].
GraphQLListType<Value, Serialized> listOf<Value, Serialized>(
        GraphQLType<Value, Serialized> innerType) =>
    new GraphQLListType<Value, Serialized>(innerType);

/// A special [GraphQLType] that indicates that input vales should be a list of another type, [ofType].
class GraphQLListType<Value, Serialized>
    extends GraphQLType<List<Value>, List<Serialized>>
    with _NonNullableMixin<List<Value>, List<Serialized>> {
  final GraphQLType<Value, Serialized> ofType;

  GraphQLListType(this.ofType);

  @override
  List<Serialized> convert(value) {
    if (value is Iterable) {
      return value.cast<Serialized>().toList();
    } else {
      return super.convert(value);
    }
  }

  @override
  String get name => null;

  @override
  String get description =>
      'A list of items of type ${ofType.name ?? '(${ofType.description}).'}';

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
      var result = ofType.validate(k, v);
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
    return serialized.map<Value>(ofType.deserialize).toList();
  }

  @override
  List<Serialized> serialize(List<Value> value) {
    return value.map<Serialized>(ofType.serialize).toList();
  }

  @override
  String toString() => '[$ofType]';

  @override
  bool operator ==(other) => other is GraphQLListType && other.ofType == ofType;

  @override
  GraphQLType<List<Value>, List<Serialized>> coerceToInputObject() =>
      new GraphQLListType<Value, Serialized>(ofType.coerceToInputObject());
}

abstract class _NonNullableMixin<Value, Serialized>
    implements GraphQLType<Value, Serialized> {
  GraphQLType<Value, Serialized> _nonNullableCache;

  GraphQLType<Value, Serialized> nonNullable() => _nonNullableCache ??=
      new GraphQLNonNullableType<Value, Serialized>._(this);
}

/// A special [GraphQLType] that indicates that input values should both be non-null, and be valid when asserted against another type, named [ofType].
class GraphQLNonNullableType<Value, Serialized>
    extends GraphQLType<Value, Serialized> {
  final GraphQLType<Value, Serialized> ofType;

  GraphQLNonNullableType._(this.ofType);

  @override
  String get name => null; //innerType.name;

  @override
  String get description =>
      'A non-nullable binding to ${ofType.name ?? '(${ofType.description}).'}';

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
    return ofType.validate(key, input);
  }

  @override
  Value deserialize(Serialized serialized) {
    return ofType.deserialize(serialized);
  }

  @override
  Serialized serialize(Value value) {
    return ofType.serialize(value);
  }

  @override
  String toString() {
    return '$ofType!';
  }

  @override
  bool operator ==(other) =>
      other is GraphQLNonNullableType && other.ofType == ofType;

  @override
  GraphQLType<Value, Serialized> coerceToInputObject() {
    return ofType.coerceToInputObject().nonNullable();
  }
}
