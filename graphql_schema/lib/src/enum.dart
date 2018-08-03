part of graphql_schema.src.schema;

class GraphQLEnumType extends _GraphQLStringType {
  final String name;
  final List<String> values;
  final String description;

  GraphQLEnumType(this.name, this.values, {this.description}) : super._();

  @override
  ValidationResult<String> validate(String key, String input) {
    var result = super.validate(key, input);

    if (result.successful && !values.contains(result.value)) {
      return result._asFailure()
        ..errors.add(
            '"${result.value}" is not a valid value for the enum "$name".');
    }

    return result;
  }
}
