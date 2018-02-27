library angel_serialize_generator;

import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;
import 'build_context.dart';
import 'context.dart';

part 'model.dart';

/// Converts a [DartType] to a [TypeReference].
TypeReference convertTypeReference(DartType t) {
  return new TypeReference((b) {
    b..symbol = t.name;

    if (t is InterfaceType) {
      b.types.addAll(t.typeArguments.map(convertTypeReference));
    }
  });
}

class JsonModelGenerator extends GeneratorForAnnotation<Serializable> {
  final bool autoSnakeCaseNames;
  final bool autoIdAndDateFields;

  const JsonModelGenerator(
      {this.autoSnakeCaseNames: true, this.autoIdAndDateFields: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader reader, BuildStep buildStep) async {
    if (element.kind != ElementKind.CLASS)
      throw 'Only classes can be annotated with a @Serializable() annotation.';

    var ctx = await buildContext(
        element,
        serializable,
        buildStep,
        await buildStep.resolver,
        autoSnakeCaseNames != false,
        autoIdAndDateFields != false);

    var lib = new File((b) {
      generateClass(ctx, b);
    });

    var buf = lib.accept(new DartEmitter());
    return buf.toString();
  }

  /// Generate an extended model class.
  void generateClass(BuildContext ctx, FileBuilder file) {
    file.body.add(new Class((clazz) {
      clazz
        ..name = ctx.modelClassNameRecase.pascalCase
        ..extend = new Reference(ctx.originalClassName);

      for (var field in ctx.fields) {
        clazz.fields.add(new Field((b) {
          b
            ..name = field.name
            ..modifier = FieldModifier.final$
            ..type = convertTypeReference(field.type);
        }));
      }

      generateConstructor(ctx, clazz, file);
    }));
  }

  /// Generate a constructor with named parameters.
  void generateConstructor(
      BuildContext ctx, ClassBuilder clazz, FileBuilder file) {
    clazz.constructors.add(new Constructor((constructor) {
      for (var field in ctx.fields) {
        constructor.optionalParameters.add(new Parameter((b) {
          b
            ..name = field.name
            ..named = true
            ..toThis = true;
        }));
      }
    }));
  }
}
