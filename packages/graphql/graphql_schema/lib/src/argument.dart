part of graphql_schema.src.schema;

/// An input to a GraphQL field. This is analogous to a function parameter in Dart.
class GraphQLFieldInput<Value, Serialized> {
  /// The name of this field.
  final String name;

  /// The type that input values must conform to.
  final GraphQLType<Value, Serialized> type;

  /// An optional default value for this field.
  final Value defaultValue;

  /// An optional description for this field.
  ///
  /// This is useful when documenting your API for consumers like GraphiQL.
  final String description;

  /// If [defaultValue] is `null`, and `null` is a valid value for this parameter, set this to `true`.
  final bool defaultsToNull;

  static bool _isInputTypeOrScalar(GraphQLType type) {
    if (type is GraphQLInputObjectType) {
      return true;
    } else if (type is GraphQLUnionType) {
      return type.possibleTypes.every(_isInputTypeOrScalar);
    } else if (type is GraphQLObjectType) {
      return false;
    } else if (type is GraphQLNonNullableType) {
      return _isInputTypeOrScalar(type.ofType);
    } else if (type is GraphQLListType) {
      return _isInputTypeOrScalar(type.ofType);
    } else {
      return true;
    }
  }

  GraphQLFieldInput(this.name, this.type,
      {this.defaultValue, this.defaultsToNull: false, this.description}) {
    assert(_isInputTypeOrScalar(type),
        'All inputs to a GraphQL field must either be scalar types, or explicitly marked as INPUT_OBJECT. Call `GraphQLObjectType.asInputObject()` on any object types you are passing as inputs to a field.');
  }

  @override
  bool operator ==(other) =>
      other is GraphQLFieldInput &&
      other.name == name &&
      other.type == type &&
      other.defaultValue == other.defaultValue &&
      other.defaultsToNull == defaultsToNull &&
      other.description == description;
}
