import 'dart:async';
import 'exception.dart';
import 'reflector.dart';

class Container {
  final Reflector reflector;
  final Map<Type, dynamic> _singletons = {};
  final Map<Type, dynamic Function(Container)> _factories = {};
  final Map<String, dynamic> _namedSingletons = {};
  final Container _parent;

  Container(this.reflector) : _parent = null;

  Container._child(this._parent) : reflector = _parent.reflector;

  bool get isRoot => _parent == null;

  /// Creates a child [Container] that can define its own singletons and factories.
  ///
  /// Use this to create children of a global "scope."
  Container createChild() {
    return Container._child(this);
  }

  /// Determines if the container has an injection of the given type.
  bool has<T>([Type t]) {
    var search = this;
    t ??= T == dynamic ? t : T;

    while (search != null) {
      if (search._singletons.containsKey(t)) {
        return true;
      } else if (search._factories.containsKey(t)) {
        return true;
      } else {
        search = search._parent;
      }
    }

    return false;
  }

  /// Determines if the container has a named singleton with the given [name].
  bool hasNamed(String name) {
    var search = this;

    while (search != null) {
      if (search._namedSingletons.containsKey(name)) {
        return true;
      } else {
        search = search._parent;
      }
    }

    return false;
  }

  /// Instantiates an instance of [T], asynchronously.
  ///
  /// It is similar to [make], but resolves an injection of either
  /// `Future<T>` or `T`.
  Future<T> makeAsync<T>([Type type]) {
    type ??= T;
    Type futureType; //.Future<T>.value(null).runtimeType;

    if (T == dynamic) {
      try {
        futureType = reflector.reflectFutureOf(type).reflectedType;
      } on UnsupportedError {
        // Ignore this.
      }
    }

    if (has<T>(type)) {
      return Future<T>.value(make(type));
    } else if (has<Future<T>>()) {
      return make<Future<T>>();
    } else if (futureType != null) {
      return make(futureType);
    } else {
      throw ReflectionException(
          'No injection for Future<$type> or $type was found.');
    }
  }

  /// Instantiates an instance of [T].
  ///
  /// In contexts where a static generic type cannot be used, use
  /// the [type] argument, instead of [T].
  T make<T>([Type type]) {
    type ??= T;

    var search = this;

    while (search != null) {
      if (search._singletons.containsKey(type)) {
        // Find a singleton, if any.
        return search._singletons[type] as T;
      } else if (search._factories.containsKey(type)) {
        // Find a factory, if any.
        return search._factories[type](this) as T;
      } else {
        search = search._parent;
      }
    }

    var reflectedType = reflector.reflectType(type);
    var positional = [];
    var named = <String, dynamic>{};

    if (reflectedType is ReflectedClass) {
      bool isDefault(String name) {
        return name.isEmpty || name == reflectedType.name;
      }

      var constructor = reflectedType.constructors.firstWhere(
          (c) => isDefault(c.name),
          orElse: () => throw ReflectionException(
              '${reflectedType.name} has no default constructor, and therefore cannot be instantiated.'));

      for (var param in constructor.parameters) {
        var value = make(param.type.reflectedType);

        if (param.isNamed) {
          named[param.name] = value;
        } else {
          positional.add(value);
        }
      }

      return reflectedType.newInstance(
          isDefault(constructor.name) ? '' : constructor.name,
          positional,
          named, []).reflectee as T;
    } else {
      throw ReflectionException(
          '$type is not a class, and therefore cannot be instantiated.');
    }
  }

  /// Shorthand for registering a factory that injects a singleton when it runs.
  ///
  /// In many cases, you might prefer this to [registerFactory].
  ///
  /// Returns [f].
  T Function(Container) registerLazySingleton<T>(T Function(Container) f,
      {Type as}) {
    return registerFactory<T>(
      (container) {
        var r = f(container);
        container.registerSingleton<T>(r, as: as);
        return r;
      },
      as: as,
    );
  }

  /// Registers a factory. Any attempt to resolve the
  /// type within *this* container will return the result of [f].
  ///
  /// Returns [f].
  T Function(Container) registerFactory<T>(T Function(Container) f, {Type as}) {
    as ??= T;

    if (_factories.containsKey(as)) {
      throw StateError('This container already has a factory for $as.');
    }

    _factories[as] = f;
    return f;
  }

  /// Registers a singleton. Any attempt to resolve the
  /// type within *this* container will return [object].
  ///
  /// Returns [object].
  T registerSingleton<T>(T object, {Type as}) {
    as ??= T == dynamic ? as : T;

    if (_singletons.containsKey(as ?? object.runtimeType)) {
      throw StateError(
          'This container already has a singleton for ${as ?? object.runtimeType}.');
    }

    _singletons[as ?? object.runtimeType] = object;
    return object;
  }

  /// Finds a named singleton.
  ///
  /// In general, prefer using [registerSingleton] and [registerFactory].
  ///
  /// [findByName] is best reserved for internal logic that end users of code should
  /// not see.
  T findByName<T>(String name) {
    if (_namedSingletons.containsKey(name)) {
      return _namedSingletons[name] as T;
    } else if (_parent != null) {
      return _parent.findByName<T>(name);
    } else {
      throw StateError(
          'This container does not have a singleton named "$name".');
    }
  }

  /// Registers a *named* singleton.
  ///
  /// Note that this is not related to type-based injections, and exists as a mechanism
  /// to enable injecting multiple instances of a type within the same container hierarchy.
  T registerNamedSingleton<T>(String name, T object) {
    if (_namedSingletons.containsKey(name)) {
      throw StateError('This container already has a singleton named "$name".');
    }

    _namedSingletons[name] = object;
    return object;
  }
}
