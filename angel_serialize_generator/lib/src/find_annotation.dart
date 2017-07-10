import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/src/annotation.dart';

T findAnnotation<T>(FieldElement field, Type outType) {
  var first = field.metadata
      .firstWhere((ann) => matchAnnotation(outType, ann), orElse: () => null);
  return first == null ? null : instantiateAnnotation(first);
}
