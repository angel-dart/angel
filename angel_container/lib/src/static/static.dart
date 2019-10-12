import 'package:angel_container/angel_container.dart';

/// A [Reflector] implementation that performs simple [Map] lookups.
///
/// `package:angel_container_generator` uses this to create reflectors from analysis metadata.
class StaticReflector extends Reflector {
  final Map<Symbol, String> names;
  final Map<Type, ReflectedType> types;
  final Map<Function, ReflectedFunction> functions;
  final Map<Object, ReflectedInstance> instances;

  const StaticReflector(
      {this.names = const {},
      this.types = const {},
      this.functions = const {},
      this.instances = const {}});

  @override
  String getName(Symbol symbol) {
    if (!names.containsKey(symbol)) {
      throw ArgumentError(
          'The value of $symbol is unknown - it was not generated.');
    }

    return names[symbol];
  }

  @override
  ReflectedClass reflectClass(Type clazz) =>
      reflectType(clazz) as ReflectedClass;

  @override
  ReflectedFunction reflectFunction(Function function) {
    if (!functions.containsKey(function)) {
      throw ArgumentError(
          'There is no reflection information available about $function.');
    }

    return functions[function];
  }

  @override
  ReflectedInstance reflectInstance(Object object) {
    if (!instances.containsKey(object)) {
      throw ArgumentError(
          'There is no reflection information available about $object.');
    }

    return instances[object];
  }

  @override
  ReflectedType reflectType(Type type) {
    if (!types.containsKey(type)) {
      throw ArgumentError(
          'There is no reflection information available about $type.');
    }

    return types[type];
  }
}
