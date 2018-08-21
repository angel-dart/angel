import 'package:angel_container/angel_container.dart';

final RegExp straySlashes = new RegExp(r'(^/+)|(/+$)');

matchingAnnotation(List<ReflectedInstance> metadata, Type T) {
  for (ReflectedInstance metaDatum in metadata) {
    if (metaDatum.type.reflectedType == T) {
      return metaDatum.reflectee;
    }
  }

  return null;
}

getAnnotation(obj, Type T, Reflector reflector) {
  if (reflector == null) {
    return null;
  } else {
    if (obj is Function) {
      var methodMirror = reflector.reflectFunction(obj);
      return matchingAnnotation(methodMirror.annotations, T);
    } else {
      var classMirror = reflector.reflectClass(obj.runtimeType as Type);
      return matchingAnnotation(classMirror.annotations, T);
    }
  }
}
