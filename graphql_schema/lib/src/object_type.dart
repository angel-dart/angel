part of graphql_schema.src.schema;

class GraphQLObjectType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  final String name;
  final String description;
  final List<GraphQLObjectField> fields = [];
  final bool isInterface;

  final List<GraphQLObjectType> _interfaces = [];

  final List<GraphQLObjectType> _possibleTypes = [];

  /// A list of other types that this object type is known to implement.
  List<GraphQLObjectType> get interfaces =>
      new List<GraphQLObjectType>.unmodifiable(_interfaces);

  /// A list of other types that implement this interface.
  List<GraphQLObjectType> get possibleTypes =>
      new List<GraphQLObjectType>.unmodifiable(_possibleTypes);

  GraphQLObjectType(this.name, this.description, {this.isInterface: false});

  @override
  GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
      coerceToInputObject() {
    return asInputObject('${name}Input', description: description);
  }

  /// Converts [this] into a [GraphQLInputObjectType].
  GraphQLInputObjectType asInputObject(String name, {String description}) {
    return new GraphQLInputObjectType(name,
        description: description ?? this.description,
        inputFields: fields.map((f) => new GraphQLInputObjectField(
            f.name, f.type.coerceToInputObject(),
            description: f.description)));
  }

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

    if (isInterface) {
      List<String> errors = [];

      for (var type in possibleTypes) {
        var result = type.validate(key, input);

        if (result.successful) {
          return result;
        } else {
          errors.addAll(result.errors);
        }
      }

      return new ValidationResult<Map<String, dynamic>>._failure(errors);
    }

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
        errors.add(
            'Unexpected field "$k" encountered in $key. Accepted values on type $name: ${fields.map((f) => f.name).toList()}');
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

  bool isImplementationOf(GraphQLObjectType type) {
    if (type == this) {
      return true;
    } else if (interfaces.contains(type)) {
      return true;
    } else if (interfaces.isNotEmpty) {
      return interfaces.any((t) => t.isImplementationOf(type));
    } else {
      return false;
    }
  }

  @override
  bool operator ==(other) {
    return other is GraphQLObjectType &&
        other.name == name &&
        other.description == description &&
        other.isInterface == isInterface &&
        const ListEquality<GraphQLObjectField>().equals(other.fields, fields) &&
//        const ListEquality<GraphQLObjectType>() Removed, as it causes a stack overflow :(
//            .equals(other.interfaces, interfaces) &&
        const ListEquality<GraphQLObjectType>()
            .equals(other.possibleTypes, possibleTypes);
  }
}

Map<String, dynamic> _foldToStringDynamic(Map map) {
  return map == null
      ? null
      : map.keys.fold<Map<String, dynamic>>(
          <String, dynamic>{}, (out, k) => out..[k.toString()] = map[k]);
}

class GraphQLInputObjectType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  final String name;
  final String description;
  final List<GraphQLInputObjectField> inputFields = [];

  GraphQLInputObjectType(this.name,
      {this.description,
      Iterable<GraphQLInputObjectField> inputFields: const []}) {
    this.inputFields.addAll(inputFields ?? const <GraphQLInputObjectField>[]);
  }

  @override
  ValidationResult<Map<String, dynamic>> validate(String key, Map input) {
    if (input is! Map)
      return new ValidationResult._failure(['Expected "$key" to be a Map.']);

    var out = {};
    List<String> errors = [];

    for (var field in inputFields) {
      if (field.type is GraphQLNonNullableType) {
        if (!input.containsKey(field.name) || input[field.name] == null) {
          errors.add(
              'Field "${field.name}, of type ${field.type} cannot be null."');
        }
      }
    }

    input.keys.forEach((k) {
      var field =
          inputFields.firstWhere((f) => f.name == k, orElse: () => null);

      if (field == null) {
        errors.add(
            'Unexpected field "$k" encountered in $key. Accepted values on type $name: ${inputFields.map((f) => f.name).toList()}');
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
      var field =
          inputFields.firstWhere((f) => f.name == k, orElse: () => null);
      if (field == null)
        throw new UnsupportedError(
            'Cannot serialize field "$k", which was not defined in the schema.');
      return out..[k.toString()] = field.type.serialize(value[k]);
    });
  }

  @override
  Map<String, dynamic> deserialize(Map value) {
    return value.keys.fold<Map<String, dynamic>>({}, (out, k) {
      var field =
          inputFields.firstWhere((f) => f.name == k, orElse: () => null);
      if (field == null)
        throw new UnsupportedError('Unexpected field "$k" encountered in map.');
      return out..[k.toString()] = field.type.deserialize(value[k]);
    });
  }

  @override
  bool operator ==(other) {
    return other is GraphQLInputObjectType &&
        other.name == name &&
        other.description == description &&
        const ListEquality<GraphQLInputObjectField>()
            .equals(other.inputFields, inputFields);
  }

  @override
  GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
      coerceToInputObject() => this;
}

class GraphQLInputObjectField<Value, Serialized> {
  final String name;
  final GraphQLType<Value, Serialized> type;
  final String description;
  final Value defaultValue;

  GraphQLInputObjectField(this.name, this.type,
      {this.description, this.defaultValue});

  @override
  bool operator ==(other) =>
      other is GraphQLInputObjectField &&
      other.name == name &&
      other.type == type &&
      other.description == description &&
      other.defaultValue == defaultValue;
}
