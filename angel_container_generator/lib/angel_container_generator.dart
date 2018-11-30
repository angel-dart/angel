import 'package:angel_container/angel_container.dart';
import 'package:reflectable/reflectable.dart';

/// A [Reflectable] instance that can be used as an annotation on types to generate metadata for them.
const Reflectable contained = const ContainedReflectable();

class ContainedReflectable extends Reflectable {
  const ContainedReflectable()
      : super(
            declarationsCapability,
            instanceInvokeCapability,
            invokingCapability,
            metadataCapability,
            newInstanceCapability,
            reflectedTypeCapability,
            typeRelationsCapability);
}

/// A [Reflector] instance that uses a [Reflectable] to reflect upon data.
class GeneratedReflector implements Reflector {
  final Reflectable reflectable;

  const GeneratedReflector([this.reflectable = contained]);

  @override
  String getName(Symbol symbol) {
    // TODO: implement getName
    throw new UnimplementedError();
  }

  @override
  ReflectedClass reflectClass(Type clazz) {
    return reflectType(clazz) as ReflectedClass;
  }

  @override
  ReflectedFunction reflectFunction(Function function) {
    // TODO: implement reflectFunction
    throw new UnimplementedError();
  }

  @override
  ReflectedInstance reflectInstance(Object object) {
    if (!reflectable.canReflect(object)) {
      throw new UnsupportedError('Cannot reflect $object.');
    } else {
      return new _GeneratedReflectedInstance(reflectable.reflect(object), this);
    }
  }

  @override
  ReflectedType reflectType(Type type) {
    if (!reflectable.canReflectType(type)) {
      throw new UnsupportedError('Cannot reflect $type.');
    } else {
      var mirror = reflectable.reflectType(type);
      return mirror is ClassMirror
          ? new _GeneratedReflectedClass(mirror, this)
          : new _GeneratedReflectedType(mirror);
    }
  }
}

class _GeneratedReflectedInstance extends ReflectedInstance {
  final InstanceMirror mirror;

  _GeneratedReflectedInstance(this.mirror, Reflector reflector)
      : super(null, new _GeneratedReflectedClass(mirror.type, reflector),
            mirror.reflectee);

  @override
  ReflectedType get type => clazz;

  @override
  ReflectedInstance getField(String name) {
    return mirror.invokeGetter(name);
  }
}

class _GeneratedReflectedClass extends ReflectedClass {
  final ClassMirror mirror;
  final Reflector reflector;

  _GeneratedReflectedClass(this.mirror, this.reflector)
      : super(
            mirror.simpleName,
            mirror.typeVariables.map(_convertTypeVariable).toList(),
            null,
            _constructorsOf(mirror.declarations, reflector),
            _declarationsOf(mirror.declarations, reflector),
            mirror.reflectedType);

  @override
  List<ReflectedInstance> get annotations =>
      mirror.metadata.map(reflector.reflectInstance).toList();

  @override
  bool isAssignableTo(ReflectedType other) {
    if (other is _GeneratedReflectedClass) {
      return mirror.isAssignableTo(other.mirror);
    } else if (other is _GeneratedReflectedType) {
      return mirror.isAssignableTo(other.mirror);
    } else {
      return false;
    }
  }

  @override
  ReflectedInstance newInstance(
      String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    return mirror.newInstance(constructorName, positionalArguments,
        namedArguments.map((k, v) => new MapEntry(new Symbol(k), v)));
  }
}

class _GeneratedReflectedType extends ReflectedType {
  final TypeMirror mirror;

  _GeneratedReflectedType(this.mirror)
      : super(
            mirror.simpleName,
            mirror.typeVariables.map(_convertTypeVariable).toList(),
            mirror.reflectedType);

  @override
  bool isAssignableTo(ReflectedType other) {
    if (other is _GeneratedReflectedClass) {
      return mirror.isAssignableTo(other.mirror);
    } else if (other is _GeneratedReflectedType) {
      return mirror.isAssignableTo(other.mirror);
    } else {
      return false;
    }
  }

  @override
  ReflectedInstance newInstance(
      String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    throw new UnsupportedError(
        'Cannot create a new instance of $reflectedType.');
  }
}

// TODO: Reflect functions?
List<ReflectedFunction> _constructorsOf(
    Map<String, DeclarationMirror> map, Reflector reflector) {
  print(map);
  return map.entries.fold<List<ReflectedFunction>>([], (out, entry) {
    var k = entry.key, v = entry.value;
    return out;
  });
}

List<ReflectedDeclaration> _declarationsOf(
    Map<String, DeclarationMirror> map, Reflector reflector) {
  print(map);
  return map.entries.fold<List<ReflectedDeclaration>>([], (out, entry) {
    var k = entry.key, v = entry.value;
  });
}

ReflectedTypeParameter _convertTypeVariable(TypeVariableMirror mirror) {
  return new ReflectedTypeParameter(mirror.simpleName);
}
