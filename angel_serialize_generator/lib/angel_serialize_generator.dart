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

class JsonModelGenerator extends GeneratorForAnnotation<Serializable> {
  final bool autoSnakeCaseNames;
  final bool autoIdAndDateFields;

  const JsonModelGenerator(
      {this.autoSnakeCaseNames: true, this.autoIdAndDateFields: true});

  @override
  Future<String> generateForAnnotatedElement(Element element,
      ConstantReader reader, BuildStep buildStep) async {
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

  void generateClass(BuildContext ctx, FileBuilder file) {
    file.body.add(new Class((clazz) {

    }));
  }
}