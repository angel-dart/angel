import 'exception.dart';
import 'reflector.dart';

class Container {
  final Reflector reflector;
  final Map<Type, dynamic> _singletons = {};
  final Map<Type, dynamic Function(Container)> _factories = {};
  final Container _parent;

  Container(this.reflector) : _parent = null;

  Container._child(this._parent) : reflector = _parent.reflector;

  bool get isRoot => _parent == null;

  /// Creates a child [Container] that can define its own singletons and factories.
  ///
  /// Use this to create children of a global "scope."
  Container createChild() {
    return new Container._child(this);
  }

  /// Instantiates an instance of [T].
  ///
  /// In contexts where a static generic type cannot be used, use
  /// the [type] argument, instead of [T].
  T make<T>([Type type]) {
    type ??= T;

    // Find a singleton, if any.
    var search = this;

    while (search != null) {
      if (search._singletons.containsKey(type)) {
        return search._singletons[type] as T;
      } else {
        search = search._parent;
      }
    }

    // Find a factory, if any.
    search = this;

    while (search != null) {
      if (search._factories.containsKey(type)) {
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
          orElse: () => throw new ReflectionException(
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
          named, []);
    } else {
      throw new ReflectionException(
          '$type is not a class, and therefore cannot be instantiated.');
    }
  }

  void registerFactory<T>(T Function(Container) f, {Type as}) {
    as ??= T;

    if (_factories.containsKey(as)) {
      throw new StateError('This container already has a factory for $as.');
    }

    _factories[as] = f;
  }

  void registerSingleton<T>(T object, {Type as}) {
    as ??= T == dynamic ? as : T;

    if (_singletons.containsKey(as ?? object.runtimeType)) {
      throw new StateError(
          'This container already has a singleton for ${as ?? object.runtimeType}.');
    }

    _singletons[as ?? object.runtimeType] = object;
  }
}
