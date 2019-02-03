import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_serialize_generator/build_context.dart';
import 'package:angel_serialize_generator/context.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:source_gen/source_gen.dart';

/// Generates GraphQL schemas, statically.
Builder graphQLBuilder(_) {
  return SharedPartBuilder([_GraphQLGenerator()], 'graphql_generator');
}

class _GraphQLGenerator extends GeneratorForAnnotation<GraphQLClass> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is ClassElement) {
      var ctx = await buildContext(
          element, annotation, buildStep, buildStep.resolver, false);
      var lib = buildSchemaLibrary(ctx);
      return lib.accept(DartEmitter()).toString();
    } else {
      throw UnsupportedError('@GraphQLClass() is only supported on classes.');
    }
  }

  Library buildSchemaLibrary(BuildContext ctx) {
    return Library((b) {
      var clazz = ctx.clazz;
    });
  }
}
