import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'orm_build_context.dart';

Builder mongoDBOrmBuilder(_) {
  return new LibraryBuilder(new MongoDBOrmGenerator(),
      generatedExtension: '.mongodb.orm.g.dart');
}

/// Builder that generates `.orm.g.dart`, with an abstract `FooOrm` class.
class MongoDBOrmGenerator extends GeneratorForAnnotation<Orm> {
  final bool autoSnakeCaseNames;
  final bool autoIdAndDateFields;

  MongoDBOrmGenerator({this.autoSnakeCaseNames, this.autoIdAndDateFields});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is ClassElement) {
      var ctx = await buildOrmContext(element, annotation, buildStep,
          buildStep.resolver, autoSnakeCaseNames, autoIdAndDateFields);
      var lib = buildOrmLibrary(buildStep.inputId, ctx);
      return lib.accept(new DartEmitter()).toString();
    } else {
      throw 'The @Orm() annotation can only be applied to classes.';
    }
  }

  Library buildOrmLibrary(AssetId inputId, OrmBuildContext ctx) {
    return new Library((lib) {
      // Add part of
      var libFile =
          p.setExtension(p.basename(inputId.uri.path), '.orm.g.dart');
      lib.body.add(new Code("part of '$libFile';"));
    });
  }
}
