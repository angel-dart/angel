import 'dart:async';
import 'dart:mirrors';

matchingAnnotation(List<InstanceMirror> metadata, Type T) {
  for (InstanceMirror metaDatum in metadata) {
    if (metaDatum.hasReflectee) {
      var reflectee = metaDatum.reflectee;
      if (reflectee.runtimeType == T) {
        return reflectee;
      }
    }
  }
  return null;
}

getAnnotation(obj, Type T) {
  if (obj is Function || obj is Future) {
    MethodMirror methodMirror = (reflect(obj) as ClosureMirror).function;
    return matchingAnnotation(methodMirror.metadata, T);
  } else {
    ClassMirror classMirror = reflectClass(obj.runtimeType);
    return matchingAnnotation(classMirror.metadata, T);
  }
}