part of graphql_schema.src.schema;

class GraphQLObjectType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  final String name;
  final String description;
  final List<GraphQLField> fields = [];
  final bool isInterface;

  final List<GraphQLObjectType> _interfaces = [];

  final List<GraphQLObjectType> _possibleTypes = [];

  /// A list of other types that this object type is known to implement.
  List<GraphQLObjectType> get interfaces => new List<GraphQLObjectType>.unmodifiable(_interfaces);

  /// A list of other types that implement this interface.
  List<GraphQLObjectType> get possibleTypes => new List<GraphQLObjectType>.unmodifiable(_possibleTypes);

  GraphQLObjectType(this.name, this.description, {this.isInterface: false});

  void inheritFrom(GraphQLObjectType other) {
    if (!_interfaces.contains(other)) {
      _interfaces.add(other);
      other._possibleTypes.add(this);
      other._interfaces.forEach(inheritFrom);
    }
  }

  @override
  ValidationResult<Map<String, dynamic>> validate(String key, Map input) {
    if (input is! Map)
      return new ValidationResult._failure(['Expected "$key" to be a Map.']);

    var out = {};
    List<String> errors = [];

    for (var field in fields) {
      if (field.type is GraphQLNonNullableType) {
        if (!input.containsKey(field.name) || input[field.name] == null) {
          errors.add(
              'Field "${field.name}, of type ${field.type} cannot be null."');
        }
      }
    }

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
        throw new UnsupportedError(
            'Cannot serialize field "$k", which was not defined in the schema.');
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
