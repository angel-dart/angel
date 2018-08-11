import 'exception.dart';
import 'reflector.dart';

class Container {
  final Reflector reflector;
  final Map<Type, dynamic> _singletons = {};

  Container(this.reflector);

  T make<T>(Type type) {
    if (_singletons.containsKey(type)) {
      return _singletons[type] as T;
    } else {
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
  }

  void singleton(Object object, {Type as}) {
    if (_singletons.containsKey(as ?? object.runtimeType)) {
      throw new StateError(
          'This container already has a singleton for ${as ?? object.runtimeType}.');
    }

    _singletons[as ?? object.runtimeType] = object;
  }
}
