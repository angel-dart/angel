part of graphql_schema.src.schema;

/// A [GraphQLType] that specifies the shape of structured data, with multiple fields that can be resolved independently of one another.
class GraphQLObjectType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  /// The name of this type.
  final String name;

  /// An optional description of this type; useful for tools like GraphiQL.
  final String description;

  /// The list of fields that an object of this type is expected to have.
  final List<GraphQLObjectField> fields = [];

  /// `true` if this type should be treated as an *interface*, which child types can [inheritFrom].
  ///
  /// In GraphQL, the parent class is *aware* of all the [possibleTypes] that can implement it.
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
    return toInputObject('${name}Input', description: description);
  }

  /// Converts [this] into a [GraphQLInputObjectType].
  GraphQLInputObjectType toInputObject(String name, {String description}) {
    return new GraphQLInputObjectType(name,
        description: description ?? this.description,
        inputFields: fields.map((f) => new GraphQLInputObjectField(
            f.name, f.type.coerceToInputObject(),
            description: f.description)));
  }

  /// Declares that this type inherits from another parent type.
  ///
  /// This also has the side effect of notifying the parent that this type is its descendant.
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
        var result = field.type.validate(k.toString(), field.type.convert(v));

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

  /// Returns `true` if this type, or any of its parents, is a direct descendant of another given [type].
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

/// A special [GraphQLType] that specifies the shape of an object that can only be used as an input to a [GraphQLField].
///
/// GraphQL input object types are different from regular [GraphQLObjectType]s in that they do not support resolution,
/// and are overall more limiter in utility, because their only purpose is to reduce the number of parameters to a given field,
/// and to potentially reuse an input structure across multiple fields in the hierarchy.
class GraphQLInputObjectType
    extends GraphQLType<Map<String, dynamic>, Map<String, dynamic>>
    with _NonNullableMixin<Map<String, dynamic>, Map<String, dynamic>> {
  /// The name of this type.
  final String name;

  /// An optional type of this type, which is useful for tools like GraphiQL.
  final String description;

  /// A list of the fields that an input object of this type is expected to have.
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

/// A field expected within a [GraphQLInputObjectType].
class GraphQLInputObjectField<Value, Serialized> {
  /// The name of this field.
  final String name;

  /// The type that a value for this field is validated against.
  final GraphQLType<Value, Serialized> type;

  /// A description of this field, which is useful for tools like GraphiQL.
  final String description;

  /// An optional default value for this field in an input object.
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
