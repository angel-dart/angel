part of graphql_schema.src.schema;

/// `true` or `false`.
final GraphQLScalarType<bool, bool> graphQLBoolean = new _GraphQLBoolType();

/// A UTF‐8 character sequence.
final GraphQLScalarType<String, String> graphQLString =
    new _GraphQLStringType._();

/// The ID scalar type represents a unique identifier, often used to re-fetch an object or as the key for a cache.
///
/// The ID type is serialized in the same way as a String; however, defining it as an ID signifies that it is not intended to be human‐readable.
final GraphQLScalarType<String, String> graphQLId =
    new _GraphQLStringType._('ID');

/// A [DateTime], serialized as an ISO-8601 string..
final GraphQLScalarType<DateTime, String> graphQLDate =
    new _GraphQLDateType._();

/// A signed 32‐bit integer.
final GraphQLScalarType<int, int> graphQLInt = new _GraphQLNumType<int>(
    'Int', 'A signed 64-bit integer.', (x) => x is int, 'an integer');

/// A signed double-precision floating-point value.
final GraphQLScalarType<double, double> graphQLFloat =
    new _GraphQLNumType<double>(
        'Float',
        'A signed double-precision floating-point value.',
        (x) => x is double,
        'a float');

abstract class GraphQLScalarType<Value, Serialized>
    extends GraphQLType<Value, Serialized>
    with _NonNullableMixin<Value, Serialized> {
  Type get valueType => Value;
}

typedef bool _NumVerifier(x);

class _GraphQLBoolType extends GraphQLScalarType<bool, bool> {
  @override
  bool serialize(bool value) {
    return value;
  }

  @override
  String get name => 'Boolean';

  @override
  String get description => 'A boolean value; can be either true or false.';

  @override
  ValidationResult<bool> validate(String key, input) {
    if (input != null && input is! bool)
      return new ValidationResult._failure(
          ['Expected "$key" to be a boolean.']);
    return new ValidationResult._ok(input);
  }

  @override
  bool deserialize(bool serialized) {
    return serialized;
  }

  @override
  GraphQLType<bool, bool> coerceToInputObject() => this;
}

class _GraphQLNumType<T extends num> extends GraphQLScalarType<T, T> {
  final String name;
  final String description;
  final _NumVerifier verifier;
  final String expected;

  _GraphQLNumType(this.name, this.description, this.verifier, this.expected);

  @override
  ValidationResult<T> validate(String key, input) {
    if (input != null && !verifier(input))
      return new ValidationResult._failure(
          ['Expected "$key" to be $expected.']);

    return new ValidationResult._ok(input);
  }

  @override
  T deserialize(T serialized) {
    return serialized;
  }

  @override
  T serialize(T value) {
    return value;
  }

  @override
  GraphQLType<T, T> coerceToInputObject() => this;
}

class _GraphQLStringType extends GraphQLScalarType<String, String> {
  final String name;

  _GraphQLStringType._([this.name = 'String']);

  @override
  String get description => 'A character sequence.';

  @override
  String serialize(String value) => value;

  @override
  String deserialize(String serialized) => serialized;

  @override
  ValidationResult<String> validate(String key, input) =>
      input == null || input is String
          ? new ValidationResult<String>._ok(input)
          : new ValidationResult._failure(['Expected "$key" to be a string.']);

  @override
  GraphQLType<String, String> coerceToInputObject() => this;
}

class _GraphQLDateType extends GraphQLScalarType<DateTime, String>
    with _NonNullableMixin<DateTime, String> {
  _GraphQLDateType._();

  @override
  String get name => 'Date';

  @override
  String get description => 'An ISO-8601 Date.';

  @override
  String serialize(DateTime value) => value.toIso8601String();

  @override
  DateTime deserialize(String serialized) => DateTime.parse(serialized);

  @override
  ValidationResult<String> validate(String key, input) {
    if (input != null && input is! String)
      return new ValidationResult<String>._failure(
          ['$key must be an ISO 8601-formatted date string.']);
    else if (input == null) return new ValidationResult<String>._ok(input);

    try {
      DateTime.parse(input);
      return new ValidationResult<String>._ok(input);
    } on FormatException {
      return new ValidationResult<String>._failure(
          ['$key must be an ISO 8601-formatted date string.']);
    }
  }

  @override
  GraphQLType<DateTime, String> coerceToInputObject() => this;
}
