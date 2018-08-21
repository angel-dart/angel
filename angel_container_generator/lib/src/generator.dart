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
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is LibraryElement) {
      var reader = new GenerateReflectorReader(annotation);
      var generator = new ReflectorLibraryGenerator(element, reader)
        ..generate();
      return generator.toSource();
    } else if (element is ClassElement) {
      return null;
    } else {
      throw new UnsupportedError(
          '@GenerateReflector() can only be added to a library or class element.');
    }
  }
}
