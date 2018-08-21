import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angel_container/angel_container.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'library_generator.dart';
import 'util.dart';

class AngelContainerGenerator
    extends GeneratorForAnnotation<GenerateReflector> {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    var annotation = typeChecker.firstAnnotationOf(library.element);

    if (annotation == null) {
      return null;
    } else {
      var reader = new GenerateReflectorReader(new ConstantReader(annotation));
      var generator = new ReflectorLibraryGenerator(library.element, reader);
      return generator.toSource();
    }
  }

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    throw new UnimplementedError();
  }
}
