import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;
import 'build_context.dart';
import 'postgres_build_context.dart';
import 'lib_core.dart' as lib$core;

class MigrationGenerator extends GeneratorForAnnotation<ORM> {
  static final Parameter _schemaParam = new Parameter((b) {
    b
      ..name = 'schema'
      ..type = new TypeReference((b) => b.symbol = 'Schema');
  });
  static final Expression _schema = new CodeExpression(new Code('schema'));

  /// If `true` (default), then field names will automatically be (de)serialized as snake_case.
  final bool autoSnakeCaseNames;

  /// If `true` (default), then the schema will automatically add id, created_at and updated_at fields.
  final bool autoIdAndDateFields;

  const MigrationGenerator(
      {this.autoSnakeCaseNames: true, this.autoIdAndDateFields: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (buildStep.inputId.path.contains('.migration.g.dart')) {
      return null;
    }

    if (element is! ClassElement)
      throw 'Only classes can be annotated with @ORM().';
    var resolver = await buildStep.resolver;
    var ctx = await buildContext(element, reviveOrm(annotation), buildStep,
        resolver, autoSnakeCaseNames != false, autoIdAndDateFields != false);
    var lib = generateMigrationLibrary(ctx, element, resolver, buildStep);
    if (lib == null) return null;
    var emitter = new DartEmitter();
    return lib.accept(emitter).toString();
  }

  Library generateMigrationLibrary(PostgresBuildContext ctx,
      ClassElement element, Resolver resolver, BuildStep buildStep) {
    return new Library((lib) {
      lib.directives.add([
        new Directive.import('package:angel_migration/angel_migration.dart'),
      ]);

      lib.body.add(new Class((b) {
        b.name = '${ctx.modelClassName}Migration';
        b.extend = new Reference('Migration');
      }));

      lib.methods.add(buildUpMigration(ctx, lib));
      lib.methods.add(buildDownMigration(ctx));
    });
  }

  Method buildUpMigration(PostgresBuildContext ctx, LibraryBuilder lib) {
    return new Method((meth) {
      meth.name = 'up';
      meth.annotations.add(lib$core.override);
      meth.requiredParameters.add(_schemaParam);

      var closure = new Method((closure) {
        closure.requiredParameters.add(new Parameter((b) => b.name = 'table'));
        var table = new Reference('table');

        List<String> dup = [];
        bool hasOrmImport = false;
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
          }

          String methodName;
          List<Expression> positional = [literal(key)];
          Map<String, Expression> named = {};

          if (autoIdAndDateFields != false && name == 'id') methodName = 'serial';

          if (methodName == null) {
            switch (col.type) {
              case ColumnType.VAR_CHAR:
                methodName = 'varchar';
                if (col.length != null) named['length'] = literal(col.length);
                break;
              case ColumnType.SERIAL:
                methodName = 'serial';
                break;
              case ColumnType.INT:
                methodName = 'integer';
                break;
              case ColumnType.FLOAT:
                methodName = 'float';
                break;
              case ColumnType.NUMERIC:
                methodName = 'numeric';
                break;
              case ColumnType.BOOLEAN:
                methodName = 'boolean';
                break;
              case ColumnType.DATE:
                methodName = 'date';
                break;
              case ColumnType.DATE_TIME:
                methodName = 'dateTime';
                break;
              case ColumnType.TIME_STAMP:
                methodName = 'timeStamp';
                break;
              default:
                if (!hasOrmImport) {
                  hasOrmImport = true;
                  lib.directives.add(new Directive.import('package:angel_orm/angel_orm.dart'));
                }

                Expression provColumn;

                if (col.length == null) {
                  methodName = 'declare';
                  provColumn = new CodeExpression(new Code("new ColumnType('${col.type.name}')"));
                } else {
                  methodName = 'declareColumn';
                  provColumn = new CodeExpression(new Code("new Column({type: new Column('${col.type.name}'), length: ${col.length})"));
                }

                positional.add(provColumn);
                break;
            }
          }

          var field = table.property(methodName).call(positional, named);
          var cascade = <Expression Function(Expression)>[];

          if (col.defaultValue != null) {
            cascade
                .add((e) => e.property('defaultsTo').call([literal(col.defaultValue)]));
          }

          if (col.index == IndexType.PRIMARY_KEY ||
              (autoIdAndDateFields != false && name == 'id'))
            cascade.add((e) => e.property('primaryKey').call([]));
          else if (col.index == IndexType.UNIQUE)
            cascade.add((e) => e.property('unique').call([]));

          if (col.nullable != true) cascade.add((e) => e.property('notNull').call([]));

          field = cascade.isEmpty
              ? field
              : field.cascade((e) => cascade.map((f) => f(e)).toList());
          closure.addStatement(field);
        });

        ctx.relationships.forEach((name, r) {
          var relationship = ctx.populateRelationship(name);

          if (relationship.isBelongsTo) {
            var key = relationship.localKey;

            var field = table.property('integer').call([literal(key)]);
            // .references('user', 'id').onDeleteCascade()
            var ref = field.property('references').call([
              literal(relationship.foreignTable),
              literal(relationship.foreignKey),
            ]);

            if (relationship.cascadeOnDelete != false && relationship.isSingular)
              ref = ref.property('onDeleteCascade').call([]);
            return closure.addStatement(ref);
          }
        });

        meth.addStatement(_schema.property('create').call([
          literal(ctx.tableName),
          closure,
        ]));
      });
    });
  }

  Method buildDownMigration(PostgresBuildContext ctx) {
    return new Method((b) {
      b.name = 'down';
      b.requiredParameters.add(_schemaParam);
      b.annotations.add(lib$core.override);
      b.body.add(new Code("schema.drop('${ctx.tableName}')"));
    });
  }
}
