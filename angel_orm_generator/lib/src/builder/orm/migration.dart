import 'dart:async';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'build_context.dart';
import 'package:source_gen/source_gen.dart';
import 'postgres_build_context.dart';

class SqlMigrationBuilder implements Builder {
  /// If `true` (default), then field names will automatically be (de)serialized as snake_case.
  final bool autoSnakeCaseNames;

  /// If `true` (default), then the schema will automatically add id, created_at and updated_at fields.
  final bool autoIdAndDateFields;

  /// If `true` (default: `false`), then the resulting schema will generate a `TEMPORARY` table.
  final bool temporary;

  const SqlMigrationBuilder(
      {this.autoSnakeCaseNames: true,
      this.autoIdAndDateFields: true,
      this.temporary: false});

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

    var lib = await resolver.libraryFor(buildStep.inputId);
    var elements = lib.definingCompilationUnit.unit.declarations;

    if (!elements.any(
        (el) => ormTypeChecker.firstAnnotationOf(el.element) != null)) return;

    await generateSqlMigrations(lib, resolver, buildStep, up, down);
    buildStep.writeAsString(
        buildStep.inputId.changeExtension('.up.g.sql'), up.toString());
    buildStep.writeAsString(
        buildStep.inputId.changeExtension('.down.g.sql'), down.toString());
  }

  Future generateSqlMigrations(LibraryElement libraryElement, Resolver resolver,
      BuildStep buildStep, StringBuffer up, StringBuffer down) async {
    List<String> done = [];
    for (var element
        in libraryElement.definingCompilationUnit.unit.declarations) {
      if (element is ClassDeclaration && !done.contains(element.name)) {
        var ann = ormTypeChecker.firstAnnotationOf(element.element);
        if (ann != null) {
          var ctx = await buildContext(
              element.element,
              reviveOrm(new ConstantReader(ann)),
              buildStep,
              resolver,
              autoSnakeCaseNames != false,
              autoIdAndDateFields != false);
          buildUpMigration(ctx, up);
          buildDownMigration(ctx, down);
          done.add(element.name.name);
        }
      }
    }
  }

  void buildUpMigration(PostgresBuildContext ctx, StringBuffer buf) {
    if (temporary == true)
      buf.writeln('CREATE TEMPORARY TABLE "${ctx.tableName}" (');
    else
      buf.writeln('CREATE TABLE "${ctx.tableName}" (');

    List<String> dup = [];
    int i = 0;
    ctx.columnInfo.forEach((name, col) {
      var key = ctx.resolveFieldName(name);

      if (dup.contains(key))
        return;
      else {
        if (key != 'id' || autoIdAndDateFields == false) {
          // Check for relationships that might duplicate
          for (var rName in ctx.relationships.keys) {
            var relationship = ctx.populateRelationship(rName);
            if (relationship.localKey == key) return;
          }
        }

        dup.add(key);
        if (i++ > 0) buf.writeln(',');
      }

      buf.write('  "$key" ${col.type.name}');

      if (col.index == IndexType.PRIMARY_KEY)
        buf.write(' PRIMARY KEY');
      else if (col.index == IndexType.UNIQUE) buf.write(' UNIQUE');

      if (col.nullable != true) buf.write(' NOT NULLABLE');
    });

    // Relations
    ctx.relationships.forEach((name, r) {
      var relationship = ctx.populateRelationship(name);

      if (relationship.isBelongsTo) {
        var key = relationship.localKey;

        if (dup.contains(key))
          return;
        else {
          dup.add(key);
          if (i++ > 0) buf.writeln(',');
        }

        buf.write(
            '  "${relationship.localKey}" int REFERENCES ${relationship.foreignTable}(${relationship.foreignKey})');
        if (relationship.cascadeOnDelete != false && relationship.isSingular)
          buf.write(' ON DELETE CASCADE');
      }
    });

    // Primary keys, unique
    bool hasPrimary = false;
    ctx.fields.forEach((f) {
      var col = ctx.columnInfo[f.name];
      if (col != null) {
        var name = ctx.resolveFieldName(f.name);
        if (col.index == IndexType.UNIQUE) {
          if (i++ > 0) buf.writeln(',');
          buf.write('  UNIQUE($name)');
        } else if (col.index == IndexType.PRIMARY_KEY) {
          if (i++ > 0) buf.writeln(',');
          hasPrimary = true;
          buf.write('  PRIMARY KEY($name)');
        }
      }
    });

    if (!hasPrimary) {
      var idField =
          ctx.fields.firstWhere((f) => f.name == 'id', orElse: () => null);
      if (idField != null) {
        if (i++ > 0) buf.writeln(',');
        buf.write('  PRIMARY KEY(id)');
      }
    }

    buf.writeln();
    buf.writeln(');');
  }

  void buildDownMigration(PostgresBuildContext ctx, StringBuffer buf) {
    buf.writeln('DROP TABLE "${ctx.tableName}";');
  }
}
