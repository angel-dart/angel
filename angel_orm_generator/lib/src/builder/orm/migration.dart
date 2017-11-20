import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'package:code_builder/dart/core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;
import 'build_context.dart';
import 'postgres_build_context.dart';

class MigrationGenerator extends GeneratorForAnnotation<ORM> {
  static final ParameterBuilder _schemaParam = parameter('schema', [
    new TypeBuilder('Schema'),
  ]);
  static final ReferenceBuilder _schema = reference('schema');

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
    return prettyToSource(lib.buildAst());
  }

  LibraryBuilder generateMigrationLibrary(PostgresBuildContext ctx,
      ClassElement element, Resolver resolver, BuildStep buildStep) {
    var lib = new LibraryBuilder()
      ..addDirective(
          new ImportBuilder('package:angel_migration/angel_migration.dart'));

    var clazz = new ClassBuilder('${ctx.modelClassName}Migration',
        asExtends: new TypeBuilder('Migration'));
    clazz..addMethod(buildUpMigration(ctx, lib))..addMethod(buildDownMigration(ctx));

    return lib..addMember(clazz);
  }

  MethodBuilder buildUpMigration(PostgresBuildContext ctx, LibraryBuilder lib) {
    var meth = new MethodBuilder('up')..addPositional(_schemaParam);
    var closure = new MethodBuilder.closure()
      ..addPositional(parameter('table'));
    var table = reference('table');

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
      List<ExpressionBuilder> positional = [literal(key)];
      Map<String, ExpressionBuilder> named = {};

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
              lib.addDirective(new ImportBuilder('package:angel_orm/angel_orm.dart'));
            }

            ExpressionBuilder provColumn;
            var colType = new TypeBuilder('Column');
            var columnTypeType = new TypeBuilder('ColumnType');

            if (col.length == null) {
              methodName = 'declare';
              provColumn = columnTypeType.newInstance([
                literal(col.type.name),
              ]);
            } else {
              methodName = 'declareColumn';
              provColumn = colType.newInstance([], named: {
                'type': columnTypeType.newInstance([
                  literal(col.type.name),
                ]),
                'length': literal(col.length),
              });
            }

            positional.add(provColumn);
            break;
        }
      }

      var field = table.invoke(methodName, positional, namedArguments: named);
      var cascade = <ExpressionBuilder Function(ExpressionBuilder)>[];

      if (col.defaultValue != null) {
        cascade.add((e) => e.invoke('defaultsTo', [literal(col.defaultValue)]));
      }

      if (col.index == IndexType.PRIMARY_KEY ||
          (autoIdAndDateFields != false && name == 'id'))
        cascade.add((e) => e.invoke('primaryKey', []));
      else if (col.index == IndexType.UNIQUE)
        cascade.add((e) => e.invoke('unique', []));

      if (col.nullable != true) cascade.add((e) => e.invoke('notNull', []));

      field = cascade.isEmpty
          ? field
          : field.cascade((e) => cascade.map((f) => f(e)).toList());
      closure.addStatement(field);
    });

    ctx.relationships.forEach((name, r) {
      var relationship = ctx.populateRelationship(name);

      if (relationship.isBelongsTo) {
        var key = relationship.localKey;

        var field = table.invoke('integer', [literal(key)]);
        // .references('user', 'id').onDeleteCascade()
        var ref = field.invoke('references', [
          literal(relationship.foreignTable),
          literal(relationship.foreignKey),
        ]);
        if (relationship.cascadeOnDelete != false && relationship.isSingular)
          ref = ref.invoke('onDeleteCascade', []);
        return closure.addStatement(ref);
      }
    });

    meth.addStatement(_schema.invoke('create', [
      literal(ctx.tableName),
      closure,
    ]));
    return meth..addAnnotation(lib$core.override);
  }

  MethodBuilder buildDownMigration(PostgresBuildContext ctx) {
    return method('down', [
      _schemaParam,
      _schema.invoke('drop', [literal(ctx.tableName)]),
    ])
      ..addAnnotation(lib$core.override);
  }
}
