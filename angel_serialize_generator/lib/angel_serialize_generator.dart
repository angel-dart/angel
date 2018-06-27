library angel_serialize_generator;

import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;
import 'build_context.dart';
import 'context.dart';

part 'model.dart';

part 'serialize.dart';

part 'typescript.dart';

Builder jsonModelBuilder(_) {
  return new PartBuilder(
    const [const JsonModelGenerator()],
    generatedExtension: '.g.dart',
  );
}

Builder serializerBuilder(_) {
  return new PartBuilder(
    const [const SerializerGenerator()],
    generatedExtension: '.serializer.g.dart',
  );
}

Builder typescriptDefinitionBuilder(_) {
  return const TypeScriptDefinitionBuilder();
}

/// Converts a [DartType] to a [TypeReference].
TypeReference convertTypeReference(DartType t) {
  return new TypeReference((b) {
    b..symbol = t.name;

    if (t is InterfaceType) {
      b.types.addAll(t.typeArguments.map(convertTypeReference));
    }
  });
}

/// Determines if a type supports `package:angel_serialize`.
bool isModelClass(DartType t) {
  if (t == null) return false;

  if (serializableTypeChecker.hasAnnotationOf(t.element)) return true;

  if (t is InterfaceType) {
    return isModelClass(t.superclass);
  } else {
    return false;
  }
}

bool isListOrMapType(DartType t) {
  return const TypeChecker.fromRuntime(List).isAssignableFromType(t) ||
      const TypeChecker.fromRuntime(Map).isAssignableFromType(t);
}

bool isEnumType(DartType t) {
  if (t is InterfaceType) {
    return t.element.isEnum;
  }

  return false;
}

/// Determines if a [DartType] is a `List` with the first type argument being a `Model`.
bool isListModelType(InterfaceType t) {
  return const TypeChecker.fromRuntime(List).isAssignableFromType(t) &&
      t.typeArguments.length == 1 &&
      isModelClass(t.typeArguments[0]);
}

/// Determines if a [DartType] is a `Map` with the second type argument being a `Model`.
bool isMapToModelType(InterfaceType t) {
  return const TypeChecker.fromRuntime(Map).isAssignableFromType(t) &&
      t.typeArguments.length == 2 &&
      isModelClass(t.typeArguments[1]);
}

bool isAssignableToModel(DartType type) => const TypeChecker.fromRuntime(Model).isAssignableFromType(type);

/// Compute a [String] representation of a [type].
String typeToString(DartType type) {
  if (type is InterfaceType) {
    if (type.typeArguments.isEmpty) return type.name;
    return type.name +
        '<' +
        type.typeArguments.map(typeToString).join(', ') +
        '>';
  } else {
    return type.name;
  }
}
