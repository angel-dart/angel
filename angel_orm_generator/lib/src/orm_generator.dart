import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:source_gen/source_gen.dart';

import 'orm_build_context.dart';

Builder ormBuilder(BuilderOptions options) {
  return new SharedPartBuilder([
    new OrmGenerator(
        autoSnakeCaseNames: options.config['auto_snake_case_names'] != false,
        autoIdAndDateFields: options.config['auto_id_and_date_fields'] != false)
  ], 'angel_orm');
}

TypeReference futureOf(String type) {
  return new TypeReference((b) => b
    ..symbol = 'Future'
    ..types.add(refer(type)));
}

/// Builder that generates `.orm.g.dart`, with an abstract `FooOrm` class.
class OrmGenerator extends GeneratorForAnnotation<Orm> {
  final bool autoSnakeCaseNames;
  final bool autoIdAndDateFields;

  OrmGenerator({this.autoSnakeCaseNames, this.autoIdAndDateFields});

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
      // Create `FooQuery` class
      // Create `FooQueryWhere` class
      lib.body.add(buildQueryClass(ctx));
      lib.body.add(buildWhereClass(ctx));
      lib.body.add(buildValuesClass(ctx));
    });
  }

  Class buildQueryClass(OrmBuildContext ctx) {
    // TODO: Handle relations

    return new Class((clazz) {
      var rc = ctx.buildContext.modelClassNameRecase;
      var queryWhereType = refer('${rc.pascalCase}QueryWhere');
      clazz
        ..name = '${rc.pascalCase}Query'
        ..extend = new TypeReference((b) {
          b
            ..symbol = 'Query'
            ..types.addAll([
              ctx.buildContext.modelClassType,
              queryWhereType,
            ]);
        });

      // Add values
      clazz.fields.add(new Field((b) {
        var type = refer('${rc.pascalCase}QueryValues');
        b
          ..name = 'values'
          ..modifier = FieldModifier.final$
          ..annotations.add(refer('override'))
          ..type = type
          ..assignment = type.newInstance([]).code;
      }));

      // Add tableName
      clazz.methods.add(new Method((m) {
        m
          ..name = 'tableName'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = new Block((b) {
            b.addExpression(literalString(ctx.tableName).returned);
          });
      }));

      // Add fields getter
      clazz.methods.add(new Method((m) {
        m
          ..name = 'fields'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = new Block((b) {
            var names = ctx.effectiveFields
                .map((f) =>
                    literalString(ctx.buildContext.resolveFieldName(f.name)))
                .toList();
            b.addExpression(literalConstList(names).returned);
          });
      }));

      // Add where member
      clazz.fields.add(new Field((b) {
        b
          ..annotations.add(refer('override'))
          ..name = 'where'
          ..modifier = FieldModifier.final$
          ..type = queryWhereType
          ..assignment = queryWhereType.newInstance([]).code;
      }));

      clazz.methods.add(new Method((b) {
        b
          ..name = 'newWhereClause'
          ..annotations.add(refer('override'))
          ..returns = queryWhereType
          ..body = new Block(
              (b) => b.addExpression(queryWhereType.newInstance([]).returned));
      }));

      // Add deserialize()
      clazz.methods.add(new Method((m) {
        m
          ..name = 'parseRow'
          ..static = true
          ..returns = ctx.buildContext.modelClassType
          ..requiredParameters.add(new Parameter((b) => b
            ..name = 'row'
            ..type = refer('List')))
          ..body = new Block((b) {
            int i = 0;
            var args = <String, Expression>{};

            for (var field in ctx.effectiveFields) {
              Reference type = convertTypeReference(field.type);
              if (isSpecialId(field)) type = refer('int');

              var expr = (refer('row').index(literalNum(i++)));
              if (isSpecialId(field))
                expr = expr.property('toString').call([]);
              else if (field is RelationFieldImpl)
                continue;
              else
                expr = expr.asA(type);

              args[field.name] = expr;
            }

            b.statements.add(new Code('if (row.every((x) => x == null)) return null;'));
            b.addExpression(ctx.buildContext.modelClassType
                .newInstance([], args).assignVar('model'));

            ctx.relations.forEach((name, relation) {
              var foreign = ctx.relationTypes[relation];
              var skipToList = refer('row')
                  .property('skip')
                  .call([literalNum(i)])
                  .property('toList')
                  .call([]);
              var parsed = refer(
                      '${foreign.buildContext.modelClassNameRecase.pascalCase}Query')
                  .property('parseRow')
                  .call([skipToList]);
              var expr =
                  refer('model').property('copyWith').call([], {name: parsed});
              var block = new Block(
                  (b) => b.addExpression(refer('model').assign(expr)));
              var blockStr = block.accept(new DartEmitter());
              var ifStr = 'if (row.length > $i) { $blockStr }';
              b.statements.add(new Code(ifStr));
              i += ctx.relationTypes[relation].effectiveFields.length;
            });

            b.addExpression(refer('model').returned);
          });
      }));

      clazz.methods.add(new Method((m) {
        m
          ..name = 'deserialize'
          ..annotations.add(refer('override'))
          ..requiredParameters.add(new Parameter((b) => b
            ..name = 'row'
            ..type = refer('List')))
          ..body = new Block((b) {
            b.addExpression(refer('parseRow').call([refer('row')]).returned);
          });
      }));

      // If there are any relations, we need some overrides.
      if (ctx.relations.isNotEmpty) {
        clazz.constructors.add(new Constructor((b) {
          b
            ..body = new Block((b) {
              ctx.relations.forEach((fieldName, relation) {
                //var name = ctx.buildContext.resolveFieldName(fieldName);
                if (relation.type == RelationshipType.belongsTo ||
                    relation.type == RelationshipType.hasOne) {
                  var foreign = ctx.relationTypes[relation];
                  var additionalFields = foreign.effectiveFields
                      .where((f) => f.name != 'id' || !isSpecialId(f))
                      .map((f) => literalString(
                          foreign.buildContext.resolveFieldName(f.name)));
                  var joinArgs = [
                    relation.foreignTable,
                    relation.localKey,
                    relation.foreignKey
                  ].map(literalString);
                  b.addExpression(refer('leftJoin').call(joinArgs, {
                    'additionalFields':
                        literalConstList(additionalFields.toList())
                  }));
                }
              });
            });
        }));

        clazz.methods.add(new Method((b) {
          b
            ..name = 'insert'
            ..annotations.add(refer('override'))
            ..requiredParameters.add(new Parameter((b) => b..name = 'executor'))
            ..body = new Block((b) {
              var inTransaction = new Method((b) {
                b
                  ..modifier = MethodModifier.async
                  ..body = new Block((b) {
                    b.addExpression(refer('super')
                        .property('insert')
                        .call([refer('executor')])
                        .awaited
                        .assignVar('result'));

                    // Just call get() again
                    b.addExpression(
                        refer('where').property('id').property('equals').call([
                      (refer('int')
                          .property('parse')
                          .call([refer('result').property('id')]))
                    ]));
                    b.addExpression(refer('result').assign(
                        refer('getOne').call([refer('executor')]).awaited));

                    b.addExpression(refer('result').returned);
                  });
              });

              b.addExpression(refer('executor')
                  .property('transaction')
                  .call([inTransaction.closure]).returned);
            });
        }));
      }
    });
  }

  bool isSpecialId(FieldElement field) {
    return (field.name == 'id' && autoIdAndDateFields);
  }

  Class buildWhereClass(OrmBuildContext ctx) {
    return new Class((clazz) {
      var rc = ctx.buildContext.modelClassNameRecase;
      clazz
        ..name = '${rc.pascalCase}QueryWhere'
        ..extend = refer('QueryWhere');

      // Build expressionBuilders getter
      clazz.methods.add(new Method((m) {
        m
          ..name = 'expressionBuilders'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = new Block((b) {
            var references = ctx.effectiveFields.map((f) => refer(f.name));
            b.addExpression(literalList(references).returned);
          });
      }));

      // Add builders for each field
      for (var field in ctx.effectiveFields) {
        // TODO: Handle fields with relations
        var name = field.name;
        Reference builderType;

        if (const TypeChecker.fromRuntime(int).isExactlyType(field.type) ||
            const TypeChecker.fromRuntime(double).isExactlyType(field.type) ||
            isSpecialId(field)) {
          builderType = new TypeReference((b) => b
            ..symbol = 'NumericSqlExpressionBuilder'
            ..types.add(refer(isSpecialId(field) ? 'int' : field.type.name)));
        } else if (const TypeChecker.fromRuntime(String)
            .isExactlyType(field.type)) {
          builderType = refer('StringSqlExpressionBuilder');
        } else if (const TypeChecker.fromRuntime(bool)
            .isExactlyType(field.type)) {
          builderType = refer('BooleanSqlExpressionBuilder');
        } else if (const TypeChecker.fromRuntime(DateTime)
            .isExactlyType(field.type)) {
          builderType = refer('DateTimeSqlExpressionBuilder');
        } else if (ctx.relations.containsKey(field.name)) {
          var relation = ctx.relations[field.name];
          if (!isBelongsRelation(relation))
            continue;
          else {
            builderType = new TypeReference((b) => b
              ..symbol = 'NumericSqlExpressionBuilder'
              ..types.add(refer('int')));
            name = relation.localKey;
          }
        } else {
          throw new UnsupportedError(
              'Cannot generate ORM code for field of type ${field.type.name}.');
        }

        clazz.fields.add(new Field((b) {
          b
            ..name = name
            ..modifier = FieldModifier.final$
            ..type = builderType
            ..assignment = builderType.newInstance([
              literalString(ctx.buildContext.resolveFieldName(field.name))
            ]).code;
        }));
      }
    });
  }

  Class buildValuesClass(OrmBuildContext ctx) {
    return new Class((clazz) {
      var rc = ctx.buildContext.modelClassNameRecase;
      clazz
        ..name = '${rc.pascalCase}QueryValues'
        ..extend = refer('MapQueryValues');

      // Each field generates a getter for setter
      for (var field in ctx.effectiveFields) {
        var name = ctx.buildContext.resolveFieldName(field.name);
        var type = isSpecialId(field)
            ? refer('int')
            : convertTypeReference(field.type);

        clazz.methods.add(new Method((b) {
          b
            ..name = field.name
            ..type = MethodType.getter
            ..returns = type
            ..body = new Block((b) => b.addExpression(
                refer('values').index(literalString(name)).asA(type).returned));
        }));

        clazz.methods.add(new Method((b) {
          b
            ..name = field.name
            ..type = MethodType.setter
            ..returns = refer('void')
            ..requiredParameters.add(new Parameter((b) => b
              ..name = 'value'
              ..type = type))
            ..body = refer('values')
                .index(literalString(name))
                .assign(refer('value'))
                .code;
        }));
      }

      // Add an copyFrom(model)
      clazz.methods.add(new Method((b) {
        b
          ..name = 'copyFrom'
          ..returns = refer('void')
          ..requiredParameters.add(new Parameter((b) => b
            ..name = 'model'
            ..type = ctx.buildContext.modelClassType))
          ..body = new Block((b) {
            var args = <String, Expression>{};

            for (var field in ctx.effectiveFields) {
              if (isSpecialId(field) || field is RelationFieldImpl) continue;
              args[ctx.buildContext.resolveFieldName(field.name)] =
                  refer('model').property(field.name);
            }

            b.addExpression(
                refer('values').property('addAll').call([literalMap(args)]));

            for (var field in ctx.effectiveFields) {
              if (field is RelationFieldImpl) {
                var original = field.originalFieldName;
                var prop = refer('model').property(original);
                // Add only if present
                var target = refer('values').index(literalString(
                    ctx.buildContext.resolveFieldName(field.name)));
                var parsedId = (refer('int')
                    .property('parse')
                    .call([prop.property('id')]));
                var cond = prop.notEqualTo(literalNull);
                var condStr = cond.accept(new DartEmitter());
                var blkStr =
                    new Block((b) => b.addExpression(target.assign(parsedId)))
                        .accept(new DartEmitter());
                var ifStmt = new Code('if ($condStr) { $blkStr }');
                b.statements.add(ifStmt);
              }
            }
          });
      }));
    });
  }
}
