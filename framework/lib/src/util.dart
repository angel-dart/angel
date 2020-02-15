import 'package:angel_container/angel_container.dart';

final RegExp straySlashes = RegExp(r'(^/+)|(/+$)');

T matchingAnnotation<T>(List<ReflectedInstance> metadata) {
  for (ReflectedInstance metaDatum in metadata) {
    if (metaDatum.type.reflectedType == T) {
      return metaDatum.reflectee as T;
    }
  }

  return null;
}

T getAnnotation<T>(obj, Reflector reflector) {
  if (reflector == null) {
    return null;
  } else {
    if (obj is Function) {
      var methodMirror = reflector.reflectFunction(obj);
      return matchingAnnotation<T>(methodMirror.annotations);
    } else {
      var classMirror = reflector.reflectClass(obj.runtimeType as Type);
      return matchingAnnotation<T>(classMirror.annotations);
    }
  }
}
