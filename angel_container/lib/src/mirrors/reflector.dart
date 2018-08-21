import 'dart:mirrors' as dart;

import 'package:angel_container/angel_container.dart';
import 'package:angel_container/src/reflector.dart';

/// A [Reflector] implementation that forwards to `dart:mirrors`.
///
/// Useful on the server, where reflection is supported.
class MirrorsReflector implements Reflector {
  const MirrorsReflector();

  @override
  String getName(Symbol symbol) => dart.MirrorSystem.getName(symbol);

  @override
  ReflectedClass reflectClass(Type clazz) {
    var mirror = dart.reflectType(clazz);

    if (mirror is dart.ClassMirror) {
      return new _ReflectedClassMirror(mirror);
    } else {
      throw new ArgumentError('$clazz is not a class.');
    }
  }

  @override
  ReflectedFunction reflectFunction(Function function) {
    var closure = dart.reflect(function) as dart.ClosureMirror;
    return new _ReflectedMethodMirror(closure.function);
  }

  @override
  ReflectedType reflectType(Type type) {
    var mirror = dart.reflectType(type);

    if (!mirror.hasReflectedType) {
      return reflectType(dynamic);
    } else {
      if (mirror is dart.ClassMirror) {
        return new _ReflectedClassMirror(mirror);
      } else {
        return new _ReflectedTypeMirror(mirror);
      }
    }
  }

  @override
  ReflectedInstance reflectInstance(Object object) {
    return new _ReflectedInstanceMirror(object);
  }
}

class _ReflectedTypeParameter extends ReflectedTypeParameter {
  final dart.TypeVariableMirror mirror;

  _ReflectedTypeParameter(this.mirror)
      : super(
            dart.MirrorSystem.getName(mirror.simpleName), mirror.reflectedType);
}

class _ReflectedTypeMirror extends ReflectedType {
  final dart.TypeMirror mirror;

  _ReflectedTypeMirror(this.mirror)
      : super(
          dart.MirrorSystem.getName(mirror.simpleName),
          mirror.typeVariables
              .map((m) => new _ReflectedTypeParameter(m))
              .toList(),
          mirror.reflectedType,
        );

  @override
  bool isAssignableTo(ReflectedType other) {
    return other is _ReflectedTypeMirror && mirror.isAssignableTo(other.mirror);
  }

  @override
  T newInstance<T>(String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    throw new ReflectionException(
        '$name is not a class, and therefore cannot be instantiated.');
  }
}

class _ReflectedClassMirror extends ReflectedClass {
  final dart.ClassMirror mirror;

  _ReflectedClassMirror(this.mirror)
      : super(
          dart.MirrorSystem.getName(mirror.simpleName),
          mirror.typeVariables
              .map((m) => new _ReflectedTypeParameter(m))
              .toList(),
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
        out.add(new _ReflectedMethodMirror(value));
      }
    }

    return out;
  }

  static List<ReflectedDeclaration> _declarationsOf(dart.ClassMirror mirror) {
    var out = <ReflectedDeclaration>[];

    for (var key in mirror.declarations.keys) {
      var value = mirror.declarations[key];

      if (value is dart.MethodMirror && !value.isConstructor) {
        out.add(new _ReflectedDeclarationMirror(
            dart.MirrorSystem.getName(key), value));
      }
    }

    return out;
  }

  @override
  List<ReflectedInstance> get annotations =>
      mirror.metadata.map((m) => new _ReflectedInstanceMirror(m)).toList();

  @override
  List<ReflectedFunction> get constructors => _constructorsOf(mirror);

  @override
  bool isAssignableTo(ReflectedType other) {
    return other is _ReflectedTypeMirror && mirror.isAssignableTo(other.mirror);
  }

  @override
  T newInstance<T>(String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    return mirror
        .newInstance(new Symbol(constructorName), positionalArguments)
        .reflectee as T;
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
  ReflectedFunction get function => new _ReflectedMethodMirror(mirror);
}

class _ReflectedInstanceMirror extends ReflectedInstance {
  final dart.InstanceMirror mirror;

  _ReflectedInstanceMirror(this.mirror)
      : super(new _ReflectedClassMirror(mirror.type),
            new _ReflectedClassMirror(mirror.type), mirror.reflectee);

  @override
  T invoke<T>(Invocation invocation) {
    return mirror.delegate(invocation) as T;
  }
}

class _ReflectedMethodMirror extends ReflectedFunction {
  final dart.MethodMirror mirror;

  _ReflectedMethodMirror(this.mirror)
      : super(
            dart.MirrorSystem.getName(mirror.simpleName),
            <ReflectedTypeParameter>[],
            mirror.metadata
                .map((mirror) => new _ReflectedInstanceMirror(mirror))
                .toList(),
            !mirror.returnType.hasReflectedType
                ? const MirrorsReflector().reflectType(dynamic)
                : const MirrorsReflector()
                    .reflectType(mirror.returnType.reflectedType),
            mirror.parameters.map(_reflectParameter).toList(),
            mirror.isGetter,
            mirror.isSetter);

  static ReflectedParameter _reflectParameter(dart.ParameterMirror mirror) {
    return new ReflectedParameter(
        dart.MirrorSystem.getName(mirror.simpleName),
        mirror.metadata
            .map((mirror) => new _ReflectedInstanceMirror(mirror))
            .toList(),
        const MirrorsReflector().reflectType(mirror.type.reflectedType),
        !mirror.isOptional,
        mirror.isNamed);
  }
}
