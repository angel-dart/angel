part of graphql_schema.src.schema;

class GraphQLObjectType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  final String name;
  final List<GraphQLField> fields = [];

  GraphQLObjectType(this.name);

  @override
  ValidationResult<Map<String, dynamic>> validate(String key, Map input) {
    if (input is! Map)
      return new ValidationResult._failure(['Expected "$key" to be a Map.']);

    var out = {};
    List<String> errors = [];

    input.keys.forEach((k) {
      var field = fields.firstWhere((f) => f.name == k, orElse: () => null);

      if (field == null) {
        errors.add('Unexpected field "$k" encountered in $key.');
      } else {
        var v = input[k];
        var result = field.type.validate(k.toString(), v);

        if (!result.successful) {
          errors.addAll(result.errors.map((s) => '$key: $s'));
        } else {
          out[k] = v;
        }
      }
    });

    if (errors.isNotEmpty) {
      return new ValidationResult._failure(errors);
    } else
      return new ValidationResult._ok(_foldToStringDynamic(out));
  }

  @override
  Map<String, dynamic> serialize(Map value) {
    return value.keys.fold<Map<String, dynamic>>({}, (out, k) {
      var field = fields.firstWhere((f) => f.name == k, orElse: () => null);
      if (field == null)
        throw new UnsupportedError('Cannot serialize field "$k", which was not defined in the schema.');
      return out..[k.toString()] = field.serialize(value[k]);
    });
  }

  @override
  Map<String, dynamic> deserialize(Map value) {
    return value.keys.fold<Map<String, dynamic>>({}, (out, k) {
      var field = fields.firstWhere((f) => f.name == k, orElse: () => null);
      if (field == null)
        throw new UnsupportedError('Unexpected field "$k" encountered in map.');
      return out..[k.toString()] = field.deserialize(value[k]);
    });
  }
}

Map<String, dynamic> _foldToStringDynamic(Map map) {
  return map == null
      ? null
      : map.keys.fold<Map<String, dynamic>>(
      <String, dynamic>{}, (out, k) => out..[k.toString()] = map[k]);
}