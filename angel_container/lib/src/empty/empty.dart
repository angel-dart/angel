import 'package:angel_container/angel_container.dart';

final Map<Symbol, String> _symbolNames = <Symbol, String>{};

/// A [Reflector] implementation that performs no actual reflection,
/// instead returning empty objects on every invocation.
///
/// Use this in contexts where you know you won't need any reflective capabilities.
class EmptyReflector extends Reflector {
  /// A [RegExp] that can be used to extract the name of a symbol without reflection.
  static final RegExp symbolRegex = RegExp(r'Symbol\("([^"]+)"\)');

  const EmptyReflector();

  @override
  String getName(Symbol symbol) {
    return _symbolNames.putIfAbsent(
        symbol, () => symbolRegex.firstMatch(symbol.toString()).group(1));
  }

  @override
  ReflectedClass reflectClass(Type clazz) {
    return const _EmptyReflectedClass();
  }

  @override
  ReflectedInstance reflectInstance(Object object) {
    return const _EmptyReflectedInstance();
  }

  @override
  ReflectedType reflectType(Type type) {
    return const _EmptyReflectedType();
  }

  @override
  ReflectedFunction reflectFunction(Function function) {
    return const _EmptyReflectedFunction();
  }
}

class _EmptyReflectedClass extends ReflectedClass {
  const _EmptyReflectedClass()
      : super(
            '(empty)',
            const <ReflectedTypeParameter>[],
            const <ReflectedInstance>[],
            const <ReflectedFunction>[],
            const <ReflectedDeclaration>[],
            Object);

  @override
  ReflectedInstance newInstance(
      String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    throw UnsupportedError(
        'Classes reflected via an EmptyReflector cannot be instantiated.');
  }

  @override
  bool isAssignableTo(ReflectedType other) {
    return other == this;
  }

  @override
  bool operator ==(other) {
    return other is ReflectedClass && other.hashCode == hashCode;
  }
}

class _EmptyReflectedType extends ReflectedType {
  const _EmptyReflectedType()
      : super('(empty)', const <ReflectedTypeParameter>[], Object);

  @override
  ReflectedInstance newInstance(
      String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]) {
    throw UnsupportedError(
        'Types reflected via an EmptyReflector cannot be instantiated.');
  }

  @override
  bool isAssignableTo(ReflectedType other) {
    return other == this;
  }

  @override
  bool operator ==(other) {
    return other is ReflectedType && other.hashCode == hashCode;
  }
}

class _EmptyReflectedInstance extends ReflectedInstance {
  const _EmptyReflectedInstance()
      : super(const _EmptyReflectedType(), const _EmptyReflectedClass(), null);

  @override
  bool operator ==(other) {
    return other is ReflectedInstance && other.hashCode == hashCode;
  }

  @override
  ReflectedInstance getField(String name) {
    throw UnsupportedError(
        'Instances reflected via an EmptyReflector cannot call getField().');
  }
}

class _EmptyReflectedFunction extends ReflectedFunction {
  const _EmptyReflectedFunction()
      : super(
            '(empty)',
            const <ReflectedTypeParameter>[],
            const <ReflectedInstance>[],
            const _EmptyReflectedType(),
            const <ReflectedParameter>[],
            false,
            false);

  @override
  ReflectedInstance invoke(Invocation invocation) {
    throw UnsupportedError(
        'Instances reflected via an EmptyReflector cannot call invoke().');
  }
}
