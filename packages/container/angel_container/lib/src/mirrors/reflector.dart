import 'dart:async';
import 'dart:mirrors' as dart;
import 'package:angel_container/angel_container.dart';
import 'package:angel_container/src/reflector.dart';

/// A [Reflector] implementation that forwards to `dart:mirrors`.
///
/// Useful on the server, where reflection is supported.
class MirrorsReflector extends Reflector {
  const MirrorsReflector();

  @override
  String getName(Symbol symbol) => dart.MirrorSystem.getName(symbol);

  @override
  ReflectedClass reflectClass(Type clazz) {
    var mirror = dart.reflectType(clazz);

    if (mirror is dart.ClassMirror) {
      return _ReflectedClassMirror(mirror);
    } else {
      throw ArgumentError('$clazz is not a class.');
    }
  }

  @override
  ReflectedFunction reflectFunction(Function function) {
    var closure = dart.reflect(function) as dart.ClosureMirror;
    return _ReflectedMethodMirror(closure.function, closure);
  }

  @override
  ReflectedType reflectType(Type type) {
    var mirror = dart.reflectType(type);

    if (!mirror.hasReflectedType) {
      return reflectType(dynamic);
    } else {
      if (mirror is dart.ClassMirror) {
        return _ReflectedClassMirror(mirror);
      } else {
        return _ReflectedTypeMirror(mirror);
      }
    }
  }

  @override
  ReflectedType reflectFutureOf(Type type) {
    var inner = reflectType(type);
    dart.TypeMirror _mirror;
    if (inner is _ReflectedClassMirror) {
      _mirror = inner.mirror;
    } else if (inner is _ReflectedTypeMirror) {
      _mirror = inner.mirror;
    } else {
      throw ArgumentError('$type is not a class or type.');
    }

    var future = dart.reflectType(Future, [_mirror.reflectedType]);
    return _ReflectedClassMirror(future as dart.ClassMirror);
  }

  @override
  ReflectedInstance reflectInstance(Object object) {
    return _ReflectedInstanceMirror(dart.reflect(object));
  }
}

class _ReflectedTypeParameter extends ReflectedTypeParameter {
  final dart.TypeVariableMirror mirror;

  _ReflectedTypeParameter(this.mirror)
      : super(dart.MirrorSystem.getName(mirror.simpleName));
}

class _ReflectedTypeMirror extends ReflectedType {
  final dart.TypeMirror mirror;

  _ReflectedTypeMirror(this.mirror)
      : super(
          dart.MirrorSystem.getName(mirror.simpleName),
          mirror.typeVariables.map((m) => _ReflectedTypeParameter(m)).toList(),
          mirror.reflectedType,
        );

  @override
  bool isAssignableTo(ReflectedType other) {
    if (other is _ReflectedClassMirror) {
      return mirror.isAssignableTo(other.mirror);
    } else if (other is _ReflectedTypeMirror) {
      return mirror.isAssignableTo(other.mirror);
    } else {
      return false;
    }
  }

  @override
  ReflectedInstance newInstance(
      String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    throw ReflectionException(
        '$name is not a class, and therefore cannot be instantiated.');
  }
}

class _ReflectedClassMirror extends ReflectedClass {
  final dart.ClassMirror mirror;

  _ReflectedClassMirror(this.mirror)
      : super(
          dart.MirrorSystem.getName(mirror.simpleName),
          mirror.typeVariables.map((m) => _ReflectedTypeParameter(m)).toList(),
          [],
          [],
          _declarationsOf(mirror),
          mirror.reflectedType,
        );

  static List<ReflectedFunction> _constructorsOf(dart.ClassMirror mirror) {
    var out = <ReflectedFunction>[];

    for (var key in mirror.declarations.keys) {
      var value = mirror.declarations[key];

      if (value is dart.MethodMirror && value.isConstructor) {
        out.add(_ReflectedMethodMirror(value));
      }
    }

    return out;
  }

  static List<ReflectedDeclaration> _declarationsOf(dart.ClassMirror mirror) {
    var out = <ReflectedDeclaration>[];

    for (var key in mirror.declarations.keys) {
      var value = mirror.declarations[key];

      if (value is dart.MethodMirror && !value.isConstructor) {
        out.add(
            _ReflectedDeclarationMirror(dart.MirrorSystem.getName(key), value));
      }
    }

    return out;
  }

  @override
  List<ReflectedInstance> get annotations =>
      mirror.metadata.map((m) => _ReflectedInstanceMirror(m)).toList();

  @override
  List<ReflectedFunction> get constructors => _constructorsOf(mirror);

  @override
  bool isAssignableTo(ReflectedType other) {
    if (other is _ReflectedClassMirror) {
      return mirror.isAssignableTo(other.mirror);
    } else if (other is _ReflectedTypeMirror) {
      return mirror.isAssignableTo(other.mirror);
    } else {
      return false;
    }
  }

  @override
  ReflectedInstance newInstance(
      String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    return _ReflectedInstanceMirror(
        mirror.newInstance(Symbol(constructorName), positionalArguments));
  }

  @override
  bool operator ==(other) {
    return other is _ReflectedClassMirror && other.mirror == mirror;
  }
}

class _ReflectedDeclarationMirror extends ReflectedDeclaration {
  final String name;
  final dart.MethodMirror mirror;

  _ReflectedDeclarationMirror(this.name, this.mirror)
      : super(name, mirror.isStatic, null);

  @override
  bool get isStatic => mirror.isStatic;

  @override
  ReflectedFunction get function => _ReflectedMethodMirror(mirror);
}

class _ReflectedInstanceMirror extends ReflectedInstance {
  final dart.InstanceMirror mirror;

  _ReflectedInstanceMirror(this.mirror)
      : super(_ReflectedClassMirror(mirror.type),
            _ReflectedClassMirror(mirror.type), mirror.reflectee);

  @override
  ReflectedInstance getField(String name) {
    return _ReflectedInstanceMirror(mirror.getField(Symbol(name)));
  }
}

class _ReflectedMethodMirror extends ReflectedFunction {
  final dart.MethodMirror mirror;
  final dart.ClosureMirror closureMirror;

  _ReflectedMethodMirror(this.mirror, [this.closureMirror])
      : super(
            dart.MirrorSystem.getName(mirror.simpleName),
            <ReflectedTypeParameter>[],
            mirror.metadata
                .map((mirror) => _ReflectedInstanceMirror(mirror))
                .toList(),
            !mirror.returnType.hasReflectedType
                ? const MirrorsReflector().reflectType(dynamic)
                : const MirrorsReflector()
                    .reflectType(mirror.returnType.reflectedType),
            mirror.parameters.map(_reflectParameter).toList(),
            mirror.isGetter,
            mirror.isSetter);

  static ReflectedParameter _reflectParameter(dart.ParameterMirror mirror) {
    return ReflectedParameter(
        dart.MirrorSystem.getName(mirror.simpleName),
        mirror.metadata
            .map((mirror) => _ReflectedInstanceMirror(mirror))
            .toList(),
        const MirrorsReflector().reflectType(mirror.type.reflectedType),
        !mirror.isOptional,
        mirror.isNamed);
  }

  @override
  ReflectedInstance invoke(Invocation invocation) {
    if (closureMirror == null) {
      throw StateError(
          'This object was reflected without a ClosureMirror, and therefore cannot be directly invoked.');
    }

    return _ReflectedInstanceMirror(closureMirror.invoke(invocation.memberName,
        invocation.positionalArguments, invocation.namedArguments));
  }
}
