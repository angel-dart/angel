import 'dart:mirrors';

import 'package:angel_serialize/angel_serialize.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:recase/recase.dart';
import 'package:tuple/tuple.dart';

/// Reflects upon a given [type] and dynamically generates a [GraphQLType] that corresponds to it.
///
/// This function is aware of the annotations from `package:angel_serialize`, and works seamlessly
/// with them.
GraphQLType objectTypeFromDartType(Type type, [List<Type> typeArguments]) {
  var tuple = new Tuple2(type, typeArguments);
  return _cache.putIfAbsent(
      tuple, () => _objectTypeFromDartType(type, typeArguments));
}

final Map<Tuple2<Type, List<Type>>, GraphQLType> _cache =
    <Tuple2<Type, List<Type>>, GraphQLType>{};

GraphQLType _objectTypeFromDartType(Type type, [List<Type> typeArguments]) {
  if (type == bool) {
    return graphQLBoolean;
  } else if (type == int) {
    return graphQLInt;
  } else if (type == double || type == num) {
    return graphQLFloat;
  } else if (type == String) {
    return graphQLString;
  } else if (type == DateTime) {
    return graphQLDate;
  }

  var mirror = reflectType(
      type, typeArguments?.isNotEmpty == true ? typeArguments : null);

  if (mirror is! ClassMirror) {
    throw new StateError(
        '$type is not a class, and therefore cannot be converted into a GraphQL object type.');
  }

  return objectTypeFromClassMirror(mirror as ClassMirror);
}

GraphQLObjectType objectTypeFromClassMirror(ClassMirror mirror) {
  var fields = <GraphQLField>[];

  for (var name in mirror.instanceMembers.keys) {
    var methodMirror = mirror.instanceMembers[name];
    var exclude = _getExclude(name, methodMirror);
    var canAdd = name != #hashCode &&
        name != #runtimeType &&
        !methodMirror.isPrivate &&
        exclude?.canSerialize != true;
    if (methodMirror.isGetter && canAdd) {
      fields.add(fieldFromGetter(name, methodMirror, exclude, mirror));
    }
  }

  return objectType(MirrorSystem.getName(mirror.simpleName), fields);
}

GraphQLField fieldFromGetter(
    Symbol name, MethodMirror mirror, Exclude exclude, ClassMirror clazz) {
  var type = objectTypeFromDartType(mirror.returnType.reflectedType,
      mirror.returnType.typeArguments.map((t) => t.reflectedType).toList());

  var nameString = _getSerializedName(name, mirror, clazz);
  var defaultValue = _getDefaultValue(mirror);

  if (nameString == 'id' && _autoNames(clazz)) {
    type = graphQLId;
  }

  return field(
    nameString,
    type: type,
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
    if (obj.reflectee is Alias) {
      var alias = obj.reflectee as Alias;
      return alias.name;
    }
  }

  // Next, search for a @Serializable()
  for (var obj in clazz.metadata) {
    if (obj.reflectee is Serializable) {
      var ann = obj.reflectee as Serializable;

      if (ann.autoSnakeCaseNames != false) {
        return new ReCase(MirrorSystem.getName(name)).snakeCase;
      }
    }
  }

  return MirrorSystem.getName(name);
}

dynamic _getDefaultValue(MethodMirror mirror) {
  // Search for a @DefaultValue
  for (var obj in mirror.metadata) {
    if (obj.reflectee is DefaultValue) {
      var ann = obj.reflectee as DefaultValue;
      return ann.value;
    }
  }

  return null;
}

bool _autoNames(ClassMirror clazz) {
  // Search for a @Serializable()
  for (var obj in clazz.metadata) {
    if (obj.reflectee is Serializable) {
      var ann = obj.reflectee as Serializable;
      return ann.autoIdAndDateFields != false;
    }
  }

  return false;
}
