import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;
import 'orm_build_context.dart';

Builder migrationBuilder(BuilderOptions options) {
  return SharedPartBuilder([
    MigrationGenerator(
        autoSnakeCaseNames: options.config['auto_snake_case_names'] != false)
  ], 'angel_migration');
}

class MigrationGenerator extends GeneratorForAnnotation<Orm> {
  static final Parameter _schemaParam = Parameter((b) => b
    ..name = 'schema'
    ..type = refer('Schema'));
  static final Reference _schema = refer('schema');

  /// If `true` (default), then field names will automatically be (de)serialized as snake_case.
  final bool autoSnakeCaseNames;

  const MigrationGenerator({this.autoSnakeCaseNames = true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      throw 'Only classes can be annotated with @ORM().';
    }

    var generateMigrations =
        annotation.peek('generateMigrations')?.boolValue ?? true;

    if (!generateMigrations) {
      return null;
    }

    var resolver = await buildStep.resolver;
    var ctx = await buildOrmContext({}, element as ClassElement, annotation,
        buildStep, resolver, autoSnakeCaseNames != false);
    var lib = generateMigrationLibrary(
        ctx, element as ClassElement, resolver, buildStep);
    if (lib == null) return null;
    return DartFormatter().format(lib.accept(DartEmitter()).toString());
  }

  Library generateMigrationLibrary(OrmBuildContext ctx, ClassElement element,
      Resolver resolver, BuildStep buildStep) {
    return Library((lib) {
      lib.body.add(Class((clazz) {
        clazz
          ..name = '${ctx.buildContext.modelClassName}Migration'
          ..extend = refer('Migration')
          ..methods
              .addAll([buildUpMigration(ctx, lib), buildDownMigration(ctx)]);
      }));
    });
  }

  Method buildUpMigration(OrmBuildContext ctx, LibraryBuilder lib) {
    return Method((meth) {
      var autoIdAndDateFields = const TypeChecker.fromRuntime(Model)
          .isAssignableFromType(ctx.buildContext.clazz.type);
      meth
        ..name = 'up'
        ..annotations.add(refer('override'))
        ..requiredParameters.add(_schemaParam);

      //var closure = Method.closure()..addPositional(parameter('table'));
      var closure = Method((closure) {
        closure
          ..requiredParameters.add(Parameter((b) => b..name = 'table'))
          ..body = Block((closureBody) {
            var table = refer('table');

            List<String> dup = [];
            ctx.columns.forEach((name, col) {
              // Skip custom-expression columns.
              if (col.hasExpression) return;

              var key = ctx.buildContext.resolveFieldName(name);

              if (dup.contains(key)) {
                return;
              } else {
                // if (key != 'id' || autoIdAndDateFields == false) {
                //   // Check for relationships that might duplicate
                //   for (var rName in ctx.relations.keys) {
                //     var relationship = ctx.relations[rName];
                //     if (relationship.localKey == key) return;
                //   }
                // }

                // Fix from: https://github.com/angel-dart/angel/issues/114#issuecomment-505525729
                if (!(col.indexType == IndexType.primaryKey ||
                    (autoIdAndDateFields != false && name == 'id'))) {
                  // Check for relationships that might duplicate
                  for (var rName in ctx.relations.keys) {
                    var relationship = ctx.relations[rName];
                    if (relationship.localKey == key) return;
                  }
                }

                dup.add(key);
              }

              String methodName;
              List<Expression> positional = [literal(key)];
              Map<String, Expression> named = {};

              if (autoIdAndDateFields != false && name == 'id') {
                methodName = 'serial';
              }

              if (methodName == null) {
                switch (col.type) {
                  case ColumnType.varChar:
                    methodName = 'varChar';
                    if (col.length != null) {
                      named['length'] = literal(col.length);
                    }
                    break;
                  case ColumnType.serial:
                    methodName = 'serial';
                    break;
                  case ColumnType.int:
                    methodName = 'integer';
                    break;
                  case ColumnType.float:
                    methodName = 'float';
                    break;
                  case ColumnType.numeric:
                    methodName = 'numeric';
                    break;
                  case ColumnType.boolean:
                    methodName = 'boolean';
                    break;
                  case ColumnType.date:
                    methodName = 'date';
                    break;
                  case ColumnType.dateTime:
                    methodName = 'dateTime';
                    break;
                  case ColumnType.timeStamp:
                    methodName = 'timeStamp';
                    break;
                  default:
                    Expression provColumn;
                    var colType = refer('Column');
                    var columnTypeType = refer('ColumnType');

                    if (col.length == null) {
                      methodName = 'declare';
                      provColumn = columnTypeType.newInstance([
                        literal(col.type.name),
                      ]);
                    } else {
                      methodName = 'declareColumn';
                      provColumn = colType.newInstance([], {
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

              var field = table.property(methodName).call(positional, named);
              var cascade = <Expression>[];

              var defaultValue = ctx.buildContext.defaults[name];

              if (defaultValue != null && !defaultValue.isNull) {
                var type = defaultValue.type;
                Expression defaultExpr;

                if (const TypeChecker.fromRuntime(RawSql)
                    .isAssignableFromType(defaultValue.type)) {
                  var value =
                      ConstantReader(defaultValue).read('value').stringValue;
                  defaultExpr =
                      refer('RawSql').constInstance([literalString(value)]);
                } else if (type is InterfaceType && type.element.isEnum) {
                  // Default to enum index.
                  try {
                    var index =
                        ConstantReader(defaultValue).read('index')?.intValue;
                    if (index != null) defaultExpr = literalNum(index);
                  } catch (_) {
                    // Extremely weird error occurs here: `Not an instance of int`.
                    // Definitely an analyzer issue.
                  }
                } else {
                  defaultExpr = CodeExpression(
                    Code(dartObjectToString(defaultValue)),
                  );
                }

                if (defaultExpr != null) {
                  cascade.add(refer('defaultsTo').call([defaultExpr]));
                }
              }

              if (col.indexType == IndexType.primaryKey ||
                  (autoIdAndDateFields != false && name == 'id')) {
                cascade.add(refer('primaryKey').call([]));
              } else if (col.indexType == IndexType.unique) {
                cascade.add(refer('unique').call([]));
              }

              if (col.isNullable != true) {
                cascade.add(refer('notNull').call([]));
              }

              if (cascade.isNotEmpty) {
                var b = StringBuffer()..writeln(field.accept(DartEmitter()));

                for (var ex in cascade) {
                  b
                    ..write('..')
                    ..writeln(ex.accept(DartEmitter()));
                }

                field = CodeExpression(Code(b.toString()));
              }

              closureBody.addExpression(field);
            });

            ctx.relations.forEach((name, r) {
              var relationship = r;

              if (relationship.type == RelationshipType.belongsTo) {
                // Fix from https://github.com/angel-dart/angel/issues/116#issuecomment-505546479
                // var key = relationship.localKey;

                // var field = table.property('integer').call([literal(key)]);
                // // .references('user', 'id').onDeleteCascade()
                var columnTypeType = refer('ColumnType');
                var key = relationship.localKey;
                var keyType = relationship
                    .foreign.columns[relationship.foreignKey].type.name;

                var field = table.property('declare').call([
                  literal(key),
                  columnTypeType.newInstance([
                    literal(keyType),
                  ])
                ]);

                var ref = field.property('references').call([
                  literal(relationship.foreignTable),
                  literal(relationship.foreignKey),
                ]);

                if (relationship.cascadeOnDelete != false &&
                    const [RelationshipType.hasOne, RelationshipType.belongsTo]
                        .contains(relationship.type)) {
                  ref = ref.property('onDeleteCascade').call([]);
                }
                closureBody.addExpression(ref);
              }
            });
          });
      });

      meth.body = Block((b) {
        b.addExpression(_schema.property('create').call([
          literal(ctx.tableName),
          closure.closure,
        ]));
      });
    });
  }

  Method buildDownMigration(OrmBuildContext ctx) {
    return Method((b) {
      b
        ..name = 'down'
        ..annotations.add(refer('override'))
        ..requiredParameters.add(_schemaParam)
        ..body = Block((b) {
          var named = <String, Expression>{};

          if (ctx.relations.values.any((r) =>
              r.type == RelationshipType.hasOne ||
              r.type == RelationshipType.hasMany ||
              r.isManyToMany)) {
            named['cascade'] = literalTrue;
          }

          b.addExpression(_schema
              .property('drop')
              .call([literalString(ctx.tableName)], named));
        });
    });
  }
}
