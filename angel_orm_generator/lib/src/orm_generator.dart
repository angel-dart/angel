import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:angel_serialize_generator/build_context.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:source_gen/source_gen.dart';

import 'orm_build_context.dart';

Builder ormBuilder(BuilderOptions options) {
  return new SharedPartBuilder([
    new OrmGenerator(
        autoSnakeCaseNames: options.config['auto_snake_case_names'] != false)
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

  OrmGenerator({this.autoSnakeCaseNames});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is ClassElement) {
      var ctx = await buildOrmContext(element, annotation, buildStep,
          buildStep.resolver, autoSnakeCaseNames);
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

      // Add _where member
      clazz.fields.add(new Field((b) {
        b
          ..name = '_where'
          ..type = queryWhereType;
      }));

      // Add where getter
      clazz.methods.add(new Method((b) {
        b
          ..name = 'where'
          ..type = MethodType.getter
          ..returns = queryWhereType
          ..annotations.add(refer('override'))
          ..body = new Block((b) => b.addExpression(refer('_where').returned));
      }));
      // newWhereClause()
      clazz.methods.add(new Method((b) {
        b
          ..name = 'newWhereClause'
          ..annotations.add(refer('override'))
          ..returns = queryWhereType
          ..body = new Block((b) => b.addExpression(
              queryWhereType.newInstance([refer('this')]).returned));
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
              var fType = field.type;
              Reference type = convertTypeReference(field.type);
              if (isSpecialId(ctx, field)) type = refer('int');

              var expr = (refer('row').index(literalNum(i++)));
              if (isSpecialId(ctx, field))
                expr = expr.property('toString').call([]);
              else if (field is RelationFieldImpl)
                continue;
              else if (ctx.columns[field.name]?.type == ColumnType.json) {
                expr = refer('json')
                    .property('decode')
                    .call([expr.asA(refer('String'))]).asA(type);
              } else if (fType is InterfaceType && fType.element.isEnum) {
                expr = type.property('values').index(expr.asA(refer('int')));
              } else
                expr = expr.asA(type);

              args[field.name] = expr;
            }

            b.statements
                .add(new Code('if (row.every((x) => x == null)) return null;'));
            b.addExpression(ctx.buildContext.modelClassType
                .newInstance([], args).assignVar('model'));

            ctx.relations.forEach((name, relation) {
              if (!const [
                RelationshipType.hasOne,
                RelationshipType.belongsTo,
                RelationshipType.hasMany
              ].contains(relation.type)) return;
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
              if (relation.type == RelationshipType.hasMany) {
                parsed = literalList([parsed]);
                var pp = parsed.accept(DartEmitter());
                parsed = CodeExpression(
                    Code('$pp.where((x) => x != null).toList()'));
              }
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
      clazz.constructors.add(new Constructor((b) {
        b
          ..body = new Block((b) {
            // Add a constructor that initializes _where
            b.addExpression(
              refer('_where')
                  .assign(queryWhereType.newInstance([refer('this')])),
            );

            ctx.relations.forEach((fieldName, relation) {
              //var name = ctx.buildContext.resolveFieldName(fieldName);
              if (relation.type == RelationshipType.belongsTo ||
                  relation.type == RelationshipType.hasOne ||
                  relation.type == RelationshipType.hasMany) {
                var foreign = ctx.relationTypes[relation];
                var additionalFields = foreign.effectiveFields
                    .where((f) => f.name != 'id' || !isSpecialId(ctx, f))
                    .map((f) => literalString(
                        foreign.buildContext.resolveFieldName(f.name)));
                var joinArgs = [relation.localKey, relation.foreignKey]
                    .map(literalString)
                    .toList();

                // Instead of passing the table as-is, we'll compile a subquery.
                if (relation.type == RelationshipType.hasMany) {
                  var foreignQueryType =
                      foreign.buildContext.modelClassNameRecase.pascalCase +
                          'Query';
                  var compiledSubquery = refer(foreignQueryType)
                      .newInstance([])
                      .property('compile')
                      .call([]);

                  joinArgs.insert(
                      0,
                      literalString('(')
                          .operatorAdd(compiledSubquery)
                          .operatorAdd(literalString(')')));
                } else {
                  joinArgs.insert(0, literalString(foreign.tableName));
                }

                b.addExpression(refer('leftJoin').call(joinArgs, {
                  'additionalFields':
                      literalConstList(additionalFields.toList())
                }));
              }
            });
          });
      }));

      // TODO: Ultimately remove the insert override
      if (false && ctx.relations.isNotEmpty) {
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

                    // Just call getOne() again
                    if (ctx.effectiveFields.any((f) =>
                        isSpecialId(ctx, f) ||
                        (ctx.columns[f.name]?.indexType ==
                            IndexType.primaryKey))) {
                      b.addExpression(refer('where')
                          .property('id')
                          .property('equals')
                          .call([
                        (refer('int')
                            .property('parse')
                            .call([refer('result').property('id')]))
                      ]));

                      b.addExpression(refer('result').assign(
                          refer('getOne').call([refer('executor')]).awaited));
                    }

                    // TODO: Remove - Fetch the results of @hasMany
                    // ctx.relations.forEach((name, relation) {
                    //   if (relation.type == RelationshipType.hasMany) {
                    //     // Call fetchLinked();
                    //     var fetchLinked = refer('fetchLinked')
                    //         .call([refer('result'), refer('executor')]).awaited;
                    //     b.addExpression(refer('result').assign(fetchLinked));
                    //   }
                    // });

                    b.addExpression(refer('result').returned);
                  });
              });

              b.addExpression(refer('executor')
                  .property('transaction')
                  .call([inTransaction.closure]).returned);
            });
        }));
      }

      // Create a Future<T> fetchLinked(T model, QueryExecutor), if necessary.
      if (false &&
          ctx.relations.values.any((r) => r.type == RelationshipType.hasMany)) {
        clazz.methods.add(new Method((b) {
          b
            ..name = 'fetchLinked'
            ..modifier = MethodModifier.async
            ..returns = new TypeReference((b) {
              b
                ..symbol = 'Future'
                ..types.add(ctx.buildContext.modelClassType);
            })
            ..requiredParameters.addAll([
              new Parameter((b) => b
                ..name = 'model'
                ..type = ctx.buildContext.modelClassType),
              new Parameter((b) => b
                ..name = 'executor'
                ..type = refer('QueryExecutor')),
            ])
            ..body = new Block((b) {
              var args = <String, Expression>{};

              ctx.relations.forEach((name, relation) {
                if (false && relation.type == RelationshipType.hasMany) {
                  // For each hasMany, we need to create a query of
                  // the corresponding type.
                  var foreign = ctx.relationTypes[relation];
                  var queryType = refer(
                      '${foreign.buildContext.modelClassNameRecase.pascalCase}Query');
                  var queryInstance = queryType.newInstance([]);

                  // Next, we need to apply a cascade that sets the correct query value.
                  var localField = ctx.effectiveFields.firstWhere(
                      (f) =>
                          ctx.buildContext.resolveFieldName(f.name) ==
                          relation.localKey, orElse: () {
                    throw '${ctx.buildContext.clazz.name} has no field that maps to the name "${relation.localKey}", '
                        'but it has a @HasMany() relation that expects such a field.';
                  });

                  var foreignField = foreign.effectiveFields.firstWhere(
                      (f) =>
                          foreign.buildContext.resolveFieldName(f.name) ==
                          relation.foreignKey, orElse: () {
                    throw '${foreign.buildContext.clazz.name} has no field that maps to the name "${relation.foreignKey}", '
                        'but ${ctx.buildContext.clazz.name} has a @HasMany() relation that expects such a field.';
                  });

                  var queryValue = (isSpecialId(ctx, localField))
                      ? 'int.parse(model.id)'
                      : 'model.${localField.name}';
                  var cascadeText =
                      '..where.${foreignField.name}.equals($queryValue)';
                  var queryText = queryInstance.accept(new DartEmitter());
                  var combinedExpr =
                      new CodeExpression(new Code('($queryText$cascadeText)'));

                  // Finally, just call get and await it.
                  var expr = combinedExpr
                      .property('get')
                      .call([refer('executor')]).awaited;
                  args[name] = expr;
                }
              });

              // Just return a copyWith
              b.addExpression(
                  refer('model').property('copyWith').call([], args).returned);
            });
        }));
      }

      // Also, if there is a @HasMany, generate overrides for query methods that
      // execute in a transaction, and invoke fetchLinked.
      if (ctx.relations.values.any((r) => r.type == RelationshipType.hasMany)) {
        for (var methodName in const ['get', 'update', 'delete']) {
          clazz.methods.add(new Method((b) {
            var type = ctx.buildContext.modelClassType.accept(DartEmitter());
            b
              ..name = methodName
              ..annotations.add(refer('override'))
              ..requiredParameters.add(new Parameter((b) => b
                ..name = 'executor'
                ..type = refer('QueryExecutor')));

            // Collect hasMany options, and ultimately merge them
            var merge = <String>[];

            ctx.relations.forEach((name, relation) {
              if (relation.type == RelationshipType.hasMany) {
                // This is only allowed with lists.
                var field =
                    ctx.buildContext.fields.firstWhere((f) => f.name == name);
                var typeLiteral =
                    convertTypeReference(field.type).accept(DartEmitter());
                merge.add('''
                $name: $typeLiteral.from(l.$name ?? [])..addAll(model.$name ?? [])
                ''');
              }
            });

            var merged = merge.join(', ');

            b.body = new Code('''
                    return super.$methodName(executor).then((result) {
                      return result.fold<List<$type>>([], (out, model) {
                        var idx = out.indexWhere((m) => m.id == model.id);

                        if (idx == -1) {
                          return out..add(model);
                        } else {
                          var l = out[idx];
                          return out..[idx] = l.copyWith($merged);
                        }
                      });
                    });
                    ''');
          }));
        }
      }
    });
  }

  bool isSpecialId(OrmBuildContext ctx, FieldElement field) {
    return field is ShimFieldImpl &&
        field is! RelationFieldImpl &&
        (field.name == 'id' &&
            const TypeChecker.fromRuntime(Model)
                .isAssignableFromType(ctx.buildContext.clazz.type));
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

      var initializers = <Code>[];

      // Add builders for each field
      for (var field in ctx.effectiveFields) {
        var name = field.name;
        var args = <Expression>[];
        DartType type;
        Reference builderType;

        try {
          type = ctx.buildContext.resolveSerializedFieldType(field.name);
        } on StateError {
          type = field.type;
        }

        if (const TypeChecker.fromRuntime(int).isExactlyType(type) ||
            const TypeChecker.fromRuntime(double).isExactlyType(type) ||
            isSpecialId(ctx, field)) {
          builderType = new TypeReference((b) => b
            ..symbol = 'NumericSqlExpressionBuilder'
            ..types.add(refer(isSpecialId(ctx, field) ? 'int' : type.name)));
        } else if (type is InterfaceType && type.element.isEnum) {
          builderType = new TypeReference((b) => b
            ..symbol = 'EnumSqlExpressionBuilder'
            ..types.add(convertTypeReference(type)));
          args.add(CodeExpression(Code('(v) => v.index')));
        } else if (const TypeChecker.fromRuntime(String).isExactlyType(type)) {
          builderType = refer('StringSqlExpressionBuilder');
        } else if (const TypeChecker.fromRuntime(bool).isExactlyType(type)) {
          builderType = refer('BooleanSqlExpressionBuilder');
        } else if (const TypeChecker.fromRuntime(DateTime)
            .isExactlyType(type)) {
          builderType = refer('DateTimeSqlExpressionBuilder');
        } else if (const TypeChecker.fromRuntime(Map)
            .isAssignableFromType(type)) {
          builderType = refer('MapSqlExpressionBuilder');
        } else if (const TypeChecker.fromRuntime(List)
            .isAssignableFromType(type)) {
          builderType = refer('ListSqlExpressionBuilder');
        } else if (ctx.relations.containsKey(field.name)) {
          var relation = ctx.relations[field.name];
          if (relation.type != RelationshipType.belongsTo)
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
            ..type = builderType;

          initializers.add(
            refer(field.name)
                .assign(builderType.newInstance([
                  refer('query'),
                  literalString(ctx.buildContext.resolveFieldName(field.name))
                ].followedBy(args)))
                .code,
          );
        }));
      }

      // Now, just add a constructor that initializes each builder.
      clazz.constructors.add(new Constructor((b) {
        b
          ..requiredParameters.add(new Parameter((b) => b
            ..name = 'query'
            ..type = refer('${rc.pascalCase}Query')))
          ..initializers.addAll(initializers);
      }));
    });
  }

  Class buildValuesClass(OrmBuildContext ctx) {
    return new Class((clazz) {
      var rc = ctx.buildContext.modelClassNameRecase;
      clazz
        ..name = '${rc.pascalCase}QueryValues'
        ..extend = refer('MapQueryValues');

      // Override casts so that we can cast Lists
      clazz.methods.add(Method((b) {
        b
          ..name = 'casts'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = Block((b) {
            var args = <String, Expression>{};

            for (var field in ctx.effectiveFields) {
              var fType = field.type;
              var name = ctx.buildContext.resolveFieldName(field.name);
              var type = ctx.columns[field.name]?.type?.name;
              if (type == null) continue;
              if (const TypeChecker.fromRuntime(List)
                  .isAssignableFromType(fType)) {
                args[name] = literalString(type);
              }
            }

            b.addExpression(literalMap(args).returned);
          });
      }));

      // Each field generates a getter for setter
      for (var field in ctx.effectiveFields) {
        var fType = field.type;
        var name = ctx.buildContext.resolveFieldName(field.name);
        var type = isSpecialId(ctx, field)
            ? refer('int')
            : convertTypeReference(field.type);

        clazz.methods.add(new Method((b) {
          var value = refer('values').index(literalString(name));

          if (fType is InterfaceType && fType.element.isEnum) {
            var asInt = value.asA(refer('int'));
            var t = convertTypeReference(fType);
            value = t.property('values').index(asInt);
          } else if (const TypeChecker.fromRuntime(List)
              .isAssignableFromType(fType)) {
            value = refer('json')
                .property('decode')
                .call([value.asA(refer('String'))]).asA(refer('List'));
          } else {
            value = value.asA(type);
          }

          b
            ..name = field.name
            ..type = MethodType.getter
            ..returns = type
            ..body = new Block((b) => b.addExpression(value.returned));
        }));

        clazz.methods.add(new Method((b) {
          Expression value = refer('value');

          if (fType is InterfaceType && fType.element.isEnum) {
            value = value.property('index');
          } else if (const TypeChecker.fromRuntime(List)
              .isAssignableFromType(fType)) {
            value = refer('json').property('encode').call([value]);
          }

          b
            ..name = field.name
            ..type = MethodType.setter
            ..requiredParameters.add(new Parameter((b) => b
              ..name = 'value'
              ..type = type))
            ..body =
                refer('values').index(literalString(name)).assign(value).code;
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
            for (var field in ctx.effectiveFields) {
              if (isSpecialId(ctx, field) || field is RelationFieldImpl)
                continue;
              b.addExpression(refer(field.name)
                  .assign(refer('model').property(field.name)));
            }

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
