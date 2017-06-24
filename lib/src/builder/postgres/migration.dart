import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:code_builder/dart/async.dart';
import 'package:code_builder/dart/core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection/inflection.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/src/annotation.dart';
import 'package:source_gen/src/utils.dart';
import 'package:source_gen/source_gen.dart';
import '../../annotations.dart';
import '../../migration.dart';
import 'package:angel_serialize/src/find_annotation.dart';
import 'build_context.dart';
import 'postgres_build_context.dart';

// TODO: HasOne, HasMany, BelongsTo
class SQLMigrationGenerator implements Builder {
  /// If "true" (default), then field names will automatically be (de)serialized as snake_case.
  final bool autoSnakeCaseNames;

  /// If "true" (default), then
  final bool autoIdAndDateFields;

  const SQLMigrationGenerator(
      {this.autoSnakeCaseNames: true, this.autoIdAndDateFields: true});

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.up.g.sql', '.down.g.sql']
      };

  @override
  Future build(BuildStep buildStep) async {
    var resolver = await buildStep.resolver;
    var up = new StringBuffer();
    var down = new StringBuffer();

    if (!await resolver.isLibrary(buildStep.inputId)) {
      return;
    }

    var lib = await resolver.getLibrary(buildStep.inputId);
    var elements = getElementsFromLibraryElement(lib);

    if (!elements.any(
        (el) => el.metadata.any((ann) => matchAnnotation(ORM, ann)))) return;

    generateSqlMigrations(lib, resolver, buildStep, up, down);
    buildStep.writeAsString(
        buildStep.inputId.changeExtension('.up.g.sql'), up.toString());
    buildStep.writeAsString(
        buildStep.inputId.changeExtension('.down.g.sql'), down.toString());
  }

  void generateSqlMigrations(LibraryElement libraryElement, Resolver resolver,
      BuildStep buildStep, StringBuffer up, StringBuffer down) {
    List<String> done = [];
    for (var element in getElementsFromLibraryElement(libraryElement)) {
      if (element is ClassElement && !done.contains(element.name)) {
        var ann = element.metadata
            .firstWhere((a) => matchAnnotation(ORM, a), orElse: () => null);
        if (ann != null) {
          var ctx = buildContext(
              element,
              instantiateAnnotation(ann),
              buildStep,
              resolver,
              autoSnakeCaseNames != false,
              autoIdAndDateFields != false);
          buildUpMigration(ctx, up);
          buildDownMigration(ctx, down);
          done.add(element.name);
        }
      }
    }
  }

  void buildUpMigration(PostgresBuildContext ctx, StringBuffer buf) {
    buf.writeln('CREATE TABLE "${ctx.tableName}" (');

    int i = 0;
    ctx.columnInfo.forEach((name, col) {
      if (i++ > 0) buf.writeln(',');
      var key = ctx.resolveFieldName(name);
      buf.write('  "$key" ${col.type.name}');

      if (col.index == IndexType.PRIMARY_KEY)
        buf.write(' PRIMARY KEY');
      else if (col.index == IndexType.UNIQUE) buf.write(' UNIQUE');

      if (col.nullable != true) buf.write(' NOT NULLABLE');
    });

    buf.writeln();
    buf.writeln(');');
  }

  void buildDownMigration(PostgresBuildContext ctx, StringBuffer buf) {
    buf.writeln('DROP TABLE "${ctx.tableName}";');
  }
}
