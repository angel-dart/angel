// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:mirrors';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:recase/recase.dart';

/// Uses `dart:mirrors` to read field names from items. If they are Maps, performs a regular lookup.
T mirrorsFieldResolver<T>(objectValue, String fieldName,
    [Map<String, dynamic> objectValues]) {
  if (objectValue is Map) {
    return objectValue[fieldName] as T;
  } else {
    return reflect(objectValue).getField(Symbol(fieldName)).reflectee as T;
  }
}

/// Reflects upon a given [type] and dynamically generates a [GraphQLType] that corresponds to it.
///
/// This function is aware of the annotations from `package:angel_serialize`, and works seamlessly
/// with them.
@deprecated
GraphQLType convertDartType(Type type, [List<Type> typeArguments]) {
  if (_cache[type] != null) {
    return _cache[type];
  } else {
    return _objectTypeFromDartType(type, typeArguments);
  }
}

/// Shorthand for [convertDartType], for when you know the result will be an object type.
@deprecated
GraphQLObjectType convertDartClass(Type type, [List<Type> typeArguments]) {
  return convertDartType(type, typeArguments) as GraphQLObjectType;
}

final Map<Type, GraphQLType> _cache = <Type, GraphQLType>{};

GraphQLType _objectTypeFromDartType(Type type, [List<Type> typeArguments]) {
  if (type == bool) {
    return graphQLBoolean;
  } else if (type == int) {
    return graphQLInt;
  } else if (type == double) {
    return graphQLFloat;
  } else if (type == num) {
    throw UnsupportedError(
        'Cannot convert `num` to a GraphQL type. Choose `int` or `float` instead.');
  } else if (type == Null) {
    throw UnsupportedError('Cannot convert `Null` to a GraphQL type.');
  } else if (type == String) {
    return graphQLString;
  } else if (type == DateTime) {
    return graphQLDate;
  }

  var mirror = reflectType(
      type, typeArguments?.isNotEmpty == true ? typeArguments : null);

  if (mirror is! ClassMirror) {
    throw StateError(
        '$type is not a class, and therefore cannot be converted into a GraphQL object type.');
  }

  var clazz = mirror as ClassMirror;

  if (clazz.isAssignableTo(reflectType(Iterable))) {
    if (clazz.typeArguments.isNotEmpty) {
      var inner = convertDartType(clazz.typeArguments[0].reflectedType);
      //if (inner == null) return null;
      return listOf(inner.nonNullable());
    }

    throw ArgumentError(
        'Cannot convert ${clazz.reflectedType}, an iterable WITHOUT a type argument, into a GraphQL type.');
  }

  if (clazz.isEnum) {
    return enumTypeFromClassMirror(clazz);
  }

  return objectTypeFromClassMirror(clazz);
}

@deprecated
GraphQLObjectType objectTypeFromClassMirror(ClassMirror mirror) {
  if (_cache[mirror.reflectedType] != null) {
    return _cache[mirror.reflectedType] as GraphQLObjectType;
  } else {}

  var fields = <GraphQLObjectField>[];
  var ready = <Symbol, MethodMirror>{};
  var forward = <Symbol, MethodMirror>{};

  void walkMap(Map<Symbol, MethodMirror> map) {
    for (var name in map.keys) {
      var methodMirror = map[name];
      var exclude = _getExclude(name, methodMirror);
      var canAdd = name != #hashCode &&
          name != #runtimeType &&
          !methodMirror.isPrivate &&
          exclude?.canSerialize != true;

      if (methodMirror.isGetter && canAdd) {
        fields.add(fieldFromGetter(name, methodMirror, exclude, mirror));
      }
    }
  }

  bool isReady(TypeMirror returnType) {
    var canContinue = returnType.reflectedType != mirror.reflectedType;

    if (canContinue &&
        returnType.isAssignableTo(reflectType(Iterable)) &&
        returnType.typeArguments.isNotEmpty &&
        !isReady(returnType.typeArguments[0])) {
      canContinue = false;
    }

    return canContinue;
  }

  void prepReadyForward(Map<Symbol, MethodMirror> map) {
    map.forEach((name, methodMirror) {
      if (methodMirror.isGetter &&
          name != #_identityHashCode &&
          name != #runtimeType &&
          name != #hashCode &&
          MirrorSystem.getName(name) != '_identityHashCode') {
        var returnType = methodMirror.returnType;

        if (isReady(returnType)) {
          ready[name] = methodMirror;
        } else {
          forward[name] = methodMirror;
        }
      }
    });
  }

  prepReadyForward(mirror.instanceMembers);

  walkMap(ready);

  if (mirror.isAbstract) {
    var decls = <Symbol, MethodMirror>{};

    mirror.declarations.forEach((name, decl) {
      if (decl is MethodMirror) {
        decls[name] = decl;
      }
    });

    ready.clear();
    forward.clear();
    prepReadyForward(decls);
    walkMap(ready);
    //walkMap(decls);
  }

  var inheritsFrom = <GraphQLObjectType>[];
  var primitiveTypes = const <Type>[
    String,
    bool,
    num,
    int,
    double,
    Object,
    dynamic,
    Null,
    Type,
    Symbol
  ];

  void walk(ClassMirror parent) {
    if (!primitiveTypes.contains(parent.reflectedType)) {
      if (parent.isAbstract) {
        var obj = convertDartType(parent.reflectedType);

        if (obj is GraphQLObjectType && !inheritsFrom.contains(obj)) {
          inheritsFrom.add(obj);
        }
      }

      walk(parent.superclass);
      parent.superinterfaces.forEach(walk);
    }
  }

  walk(mirror.superclass);
  mirror.superinterfaces.forEach(walk);

  var result = _cache[mirror.reflectedType];

  if (result == null) {
    result = objectType(
      MirrorSystem.getName(mirror.simpleName),
      fields: fields,
      isInterface: mirror.isAbstract,
      interfaces: inheritsFrom,
      description: _getDescription(mirror.metadata),
    );
    _cache[mirror.reflectedType] = result;
    walkMap(forward);
  }

  return result as GraphQLObjectType;
}

@deprecated
GraphQLEnumType enumTypeFromClassMirror(ClassMirror mirror) {
  var values = <GraphQLEnumValue>[];

  for (var name in mirror.staticMembers.keys) {
    if (name != #values) {
      var methodMirror = mirror.staticMembers[name];
      values.add(
        GraphQLEnumValue(
          MirrorSystem.getName(name),
          mirror.getField(name).reflectee,
          description: _getDescription(methodMirror.metadata),
          deprecationReason: _getDeprecationReason(methodMirror.metadata),
        ),
      );
    }
  }

  return GraphQLEnumType(
    MirrorSystem.getName(mirror.simpleName),
    values,
    description: _getDescription(mirror.metadata),
  );
}

@deprecated
GraphQLObjectField fieldFromGetter(
    Symbol name, MethodMirror mirror, Exclude exclude, ClassMirror clazz) {
  var type = _getProvidedType(mirror.metadata);
  var wasProvided = type != null;

  if (!wasProvided) {
    var returnType = mirror.returnType;

    if (!clazz.isAssignableTo(returnType)) {
      type = convertDartType(returnType.reflectedType,
          mirror.returnType.typeArguments.map((t) => t.reflectedType).toList());
    }
  }

  var nameString = _getSerializedName(name, mirror, clazz);
  var defaultValue = _getDefaultValue(mirror);

  if (!wasProvided && (nameString == 'id' && _autoNames(clazz))) {
    type = graphQLId;
  }

  return field(
    nameString,
    type,
    deprecationReason: _getDeprecationReason(mirror.metadata),
    resolve: (obj, _) {
      if (obj is Map && exclude?.canSerialize != true) {
        return obj[nameString];
      } else if (obj != null && exclude?.canSerialize != true) {
        return reflect(obj).getField(name);
      } else {
        return defaultValue;
      }
    },
  );
}

Exclude _getExclude(Symbol name, MethodMirror mirror) {
  for (var obj in mirror.metadata) {
    if (obj.reflectee is Exclude) {
      var exclude = obj.reflectee as Exclude;
      return exclude;
    }
  }

  return null;
}

String _getSerializedName(Symbol name, MethodMirror mirror, ClassMirror clazz) {
  // First search for an @Alias()
  for (var obj in mirror.metadata) {
    if (obj.reflectee is SerializableField) {
      var alias = obj.reflectee as SerializableField;
      return alias.alias;
    }
  }

  // Next, search for a @Serializable()
  for (var obj in clazz.metadata) {
    if (obj.reflectee is Serializable) {
      var ann = obj.reflectee as Serializable;

      if (ann.autoSnakeCaseNames != false) {
        return ReCase(MirrorSystem.getName(name)).snakeCase;
      }
    }
  }

  return MirrorSystem.getName(name);
}

dynamic _getDefaultValue(MethodMirror mirror) {
  // Search for a @DefaultValue
  for (var obj in mirror.metadata) {
    if (obj.reflectee is SerializableField) {
      var ann = obj.reflectee as SerializableField;
      return ann.defaultValue;
    }
  }

  return null;
}

bool _autoNames(ClassMirror clazz) {
  // Search for a @Serializable()
  for (var obj in clazz.metadata) {
    if (obj.reflectee is Serializable) {
      return true;
      // var ann = obj.reflectee as Serializable;
      // return ann.autoIdAndDateFields != false;
    }
  }

  return false;
}

String _getDeprecationReason(List<InstanceMirror> metadata) {
  for (var obj in metadata) {
    if (obj.reflectee is Deprecated) {
      var expires = (obj.reflectee as Deprecated).message;

      if (expires == deprecated.message) {
        return 'Expires after $expires';
      } else {
        return deprecated.message;
      }
    } else if (obj.reflectee is GraphQLDocumentation) {
      return (obj.reflectee as GraphQLDocumentation).deprecationReason;
    }
  }

  return null;
}

String _getDescription(List<InstanceMirror> metadata) {
  for (var obj in metadata) {
    if (obj.reflectee is GraphQLDocumentation) {
      return (obj.reflectee as GraphQLDocumentation).description;
    }
  }

  return null;
}

GraphQLType _getProvidedType(List<InstanceMirror> metadata) {
  for (var obj in metadata) {
    if (obj.reflectee is GraphQLDocumentation) {
      return (obj.reflectee as GraphQLDocumentation).type();
    }
  }

  return null;
}
