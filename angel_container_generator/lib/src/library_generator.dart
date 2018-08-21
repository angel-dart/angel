import 'package:analyzer/dart/element/element.dart';
import 'package:angel_container/angel_container.dart';
import 'package:code_builder/code_builder.dart';
import 'package:recase/recase.dart';

import 'util.dart';

class ReflectorLibraryGenerator {
  final LibraryElement element;
  final GenerateReflectorReader annotation;

  ReflectorLibraryGenerator(this.element, this.annotation);

  String toSource() {
    return generate().accept(new DartEmitter()).toString();
  }

  Library generate() {
    return new Library((lib) {
      lib.body.add(generateReflectorClass());
    });
  }

  Class generateReflectorClass() {
    return new Class((clazz) {
      // Select the name
      if (annotation.name?.isNotEmpty == true) {
        clazz.name = annotation.name;
      } else {
        var rc = new ReCase(element.name);
        clazz.name = rc.pascalCase + 'Reflector';
      }

      // implements Reflector
      clazz.implements.add(refer('Reflector'));

      // Add a const constructor
      clazz.constructors.add(new Constructor((b) {
        b..constant = true;
      }));
    });
  }
}
