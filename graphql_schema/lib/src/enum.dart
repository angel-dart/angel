part of graphql_schema.src.schema;

GraphQLEnumType enumType(String name, List<String> values,
    {String description}) {
  return new GraphQLEnumType(
      name, values.map((s) => new GraphQLEnumValue(s)).toList(),
      description: description);
}

class GraphQLEnumType extends _GraphQLStringType {
  final String name;
  final List<GraphQLEnumValue> values;
  final String description;

  GraphQLEnumType(this.name, this.values, {this.description}) : super._();

  @override
  ValidationResult<String> validate(String key, String input) {
    var result = super.validate(key, input);

    if (result.successful &&
        !values.map((v) => v.name).contains(result.value)) {
      return result._asFailure()
        ..errors.add(
            '"${result.value}" is not a valid value for the enum "$name".');
    }

    return result;
  }
}

class GraphQLEnumValue {
  final String name;
  final String deprecationReason;

  GraphQLEnumValue(this.name, {this.deprecationReason});

  bool get isDeprecated => deprecationReason != null;

  @override
  bool operator ==(other) => other is GraphQLEnumValue && other.name == name;
}
