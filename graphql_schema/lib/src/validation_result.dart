part of graphql_schema.src.schema;

/// Represents the result of asserting an input [value] against a [GraphQLType].

class ValidationResult<Value> {
  /// `true` if there were no errors during validation.
  final bool successful;

  /// The input value passed to whatever caller invoked validation.
  final Value value;

  /// A list of errors that caused validation to fail.
  final List<String> errors;

  ValidationResult._(this.successful, this.value, this.errors);

  ValidationResult._ok(this.value)
      : errors = [],
        successful = true;

  ValidationResult._failure(this.errors)
      : value = null,
        successful = false;

//  ValidationResult<T> _asFailure() {
//    return new ValidationResult<T>._(false, value, errors);
//  }
}
