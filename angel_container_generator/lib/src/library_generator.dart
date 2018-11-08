import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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

      // Generate a ReflectedClass for each type
      for (var type in annotation.types) {
        if (type is InterfaceType) {
          lib.body.add(generateReflectedClass(type));
        } else {
          // TODO: Handle these
        }
      }
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
      clazz
        ..extend = refer('StaticReflector')
        ..implements.add(refer('Reflector'));

      // Add a const constructor
      clazz.constructors.add(new Constructor((b) {
        b..constant = true;
      }));

      // Add a reflectClass that just forwards to reflectType
      clazz.methods.add(new Method((b) {
        b
          ..name = 'reflectClass'
          ..returns = refer('ReflectedClass')
          ..annotations.add(refer('override'))
          ..requiredParameters.add(new Parameter((b) => b
            ..name = 'type'
            ..type = refer('Type')))
          ..body = new Code('return reflectType(type) as ReflectedClass;');
      }));
    });
  }

  Reference _convertDartType(DartType type) {
    if (type is InterfaceType) {
      return new TypeReference((b) => b
        ..symbol = type.name
        ..types.addAll(type.typeArguments.map(_convertDartType)));
    } else {
      return refer(type.name);
    }
  }

  Class generateReflectedClass(InterfaceType type) {
    return new Class((clazz) {
      var rc = new ReCase(type.name);
      clazz
        ..name = '_Reflected${rc.pascalCase}'
        ..extend = refer('ReflectedClass');

      // Add const constructor
      var superArgs = <Expression>[
        literalString(type.name), // name
        literalConstList([]), // typeParameters
        literalConstList([]), // annotations
        literalConstList([]), // constructors
        literalConstList([]), // declarations,
        _convertDartType(type), // reflectedType
      ];
      clazz.constructors.add(new Constructor((b) => b
        ..constant = true
        ..name = '_'
        ..initializers.add(refer('super').call(superArgs).code)));
    });
  }
}
