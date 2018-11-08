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

  String get reflectorClassName {
// Select the name
    if (annotation.name?.isNotEmpty == true) {
      return new ReCase(annotation.name).pascalCase + 'Reflector';
    } else if (element.name?.isNotEmpty == true) {
      var rc = new ReCase(element.name);
      return rc.pascalCase + 'Reflector';
    } else {
      throw new StateError(
          'A statically-generated Reflector must reside in a named library, or include the `name` attribute in @GenerateReflector().');
    }
  }

  String get typeMapName => new ReCase(reflectorClassName).camelCase + 'Types';

  String toSource() {
    return generate().accept(new DartEmitter()).toString();
  }

  Library generate() {
    return new Library((lib) {
      var clazz = generateReflectorClass();

      // Generate a ReflectedClass for each type
      var staticTypes = <String, Expression>{};

      for (var type in annotation.types) {
        if (type is InterfaceType) {
          var reflected = generateReflectedClass(type);
          lib.body.add(reflected);
          staticTypes[type.name] =
              refer(reflected.name).constInstanceNamed('_', []);
        } else {
          // TODO: Handle these
        }
      }

      clazz = clazz.rebuild((b) {
        // Generate static values
        b.fields.add(new Field((b) => b
          ..name = 'staticTypes'
          ..modifier = FieldModifier.constant
          ..static = true
          ..assignment = literalConstMap(staticTypes
              .map((name, type) => new MapEntry(refer(name), type))).code));
      });

      lib.body.add(clazz);
    });
  }

  Class generateReflectorClass() {
    return new Class((clazz) {
      clazz.name = reflectorClassName;

      // extends StaticReflector
      clazz.extend = refer('StaticReflector');

      // Add a const constructor
      clazz.constructors.add(new Constructor((b) {
        b
          ..constant = true
          ..initializers.add(
              refer('super').call([], {'types': refer('staticTypes')}).code);
        // TODO: Invoke super with static info
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
