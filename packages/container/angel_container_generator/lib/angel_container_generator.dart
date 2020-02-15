import 'package:angel_container/angel_container.dart';
import 'package:reflectable/reflectable.dart';

/// A [Reflectable] instance that can be used as an annotation on types to generate metadata for them.
const Reflectable contained = const ContainedReflectable();

@contained
class ContainedReflectable extends Reflectable {
  const ContainedReflectable()
      : super(
          declarationsCapability,
          instanceInvokeCapability,
          invokingCapability,
          metadataCapability,
          newInstanceCapability,
          reflectedTypeCapability,
          typeRelationsCapability,
          typeCapability,
        );
}

/// A [Reflector] instance that uses a [Reflectable] to reflect upon data.
class GeneratedReflector extends Reflector {
  final Reflectable reflectable;

  const GeneratedReflector([this.reflectable = contained]);

  @override
  String getName(Symbol symbol) {
    return symbol.toString().substring(7);
  }

  @override
  ReflectedClass reflectClass(Type clazz) {
    return reflectType(clazz) as ReflectedClass;
  }

  @override
  ReflectedFunction reflectFunction(Function function) {
    if (!reflectable.canReflect(function)) {
      throw new UnsupportedError('Cannot reflect $function.');
    }

    var mirror = reflectable.reflect(function);

    if (mirror is ClosureMirror) {
      return new _GeneratedReflectedFunction(mirror.function, this, mirror);
    } else {
      throw new ArgumentError('$function is not a Function.');
    }
  }

  @override
  ReflectedInstance reflectInstance(Object object) {
    if (!reflectable.canReflect(object)) {
      throw new UnsupportedError('Cannot reflect $object.');
    } else {
      var mirror = reflectable.reflect(object);
      return new _GeneratedReflectedInstance(mirror, this);
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
  final GeneratedReflector reflector;

  _GeneratedReflectedInstance(this.mirror, this.reflector)
      : super(null, new _GeneratedReflectedClass(mirror.type, reflector),
            mirror.reflectee);

  @override
  ReflectedType get type => clazz;

  @override
  ReflectedInstance getField(String name) {
    var result = mirror.invokeGetter(name);
    var instance = reflector.reflectable.reflect(result);
    return new _GeneratedReflectedInstance(instance, reflector);
  }
}

class _GeneratedReflectedClass extends ReflectedClass {
  final ClassMirror mirror;
  final Reflector reflector;

  _GeneratedReflectedClass(this.mirror, this.reflector)
      : super(mirror.simpleName, null, null, null, null, mirror.reflectedType);

  @override
  List<ReflectedTypeParameter> get typeParameters =>
      mirror.typeVariables.map(_convertTypeVariable).toList();

  @override
  List<ReflectedFunction> get constructors =>
      _constructorsOf(mirror.declarations, reflector);

  @override
  List<ReflectedDeclaration> get declarations =>
      _declarationsOf(mirror.declarations, reflector);

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
    namedArguments ??= {};
    var result = mirror.newInstance(constructorName, positionalArguments,
        namedArguments.map((k, v) => new MapEntry(new Symbol(k), v)));
    return reflector.reflectInstance(result);
  }
}

class _GeneratedReflectedType extends ReflectedType {
  final TypeMirror mirror;

  _GeneratedReflectedType(this.mirror)
      : super(mirror.simpleName, null, mirror.reflectedType);

  @override
  List<ReflectedTypeParameter> get typeParameters =>
      mirror.typeVariables.map(_convertTypeVariable).toList();

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

class _GeneratedReflectedFunction extends ReflectedFunction {
  final MethodMirror mirror;
  final Reflector reflector;
  final ClosureMirror closure;

  _GeneratedReflectedFunction(this.mirror, this.reflector, [this.closure])
      : super(
            mirror.simpleName,
            [],
            null,
            !mirror.isRegularMethod
                ? null
                : new _GeneratedReflectedType(mirror.returnType),
            mirror.parameters
                .map((p) => _convertParameter(p, reflector))
                .toList(),
            mirror.isGetter,
            mirror.isSetter);

  @override
  List<ReflectedInstance> get annotations =>
      mirror.metadata.map(reflector.reflectInstance).toList();

  @override
  ReflectedInstance invoke(Invocation invocation) {
    if (closure != null) {
      throw new UnsupportedError('Only closures can be invoked directly.');
    } else {
      var result = closure.delegate(invocation);
      return reflector.reflectInstance(result);
    }
  }
}

List<ReflectedFunction> _constructorsOf(
    Map<String, DeclarationMirror> map, Reflector reflector) {
  return map.entries.fold<List<ReflectedFunction>>([], (out, entry) {
    var v = entry.value;

    if (v is MethodMirror && v.isConstructor) {
      return out..add(new _GeneratedReflectedFunction(v, reflector));
    } else {
      return out;
    }
  });
}

List<ReflectedDeclaration> _declarationsOf(
    Map<String, DeclarationMirror> map, Reflector reflector) {
  return map.entries.fold<List<ReflectedDeclaration>>([], (out, entry) {
    var v = entry.value;

    if (v is VariableMirror) {
      var decl = new ReflectedDeclaration(v.simpleName, v.isStatic, null);
      return out..add(decl);
    }
    if (v is MethodMirror) {
      var decl = new ReflectedDeclaration(v.simpleName, v.isStatic,
          new _GeneratedReflectedFunction(v, reflector));
      return out..add(decl);
    } else {
      return out;
    }
  });
}

ReflectedTypeParameter _convertTypeVariable(TypeVariableMirror mirror) {
  return new ReflectedTypeParameter(mirror.simpleName);
}

ReflectedParameter _convertParameter(
    ParameterMirror mirror, Reflector reflector) {
  return new ReflectedParameter(
      mirror.simpleName,
      mirror.metadata.map(reflector.reflectInstance).toList(),
      reflector.reflectType(mirror.type.reflectedType),
      !mirror.isOptional,
      mirror.isNamed);
}
