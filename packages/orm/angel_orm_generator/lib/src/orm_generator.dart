import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:source_gen/source_gen.dart';
import 'orm_build_context.dart';

var floatTypes = [
  ColumnType.decimal,
  ColumnType.float,
  ColumnType.numeric,
  ColumnType.real,
  const ColumnType('double precision'),
];

Builder ormBuilder(BuilderOptions options) {
  return SharedPartBuilder([
    OrmGenerator(
        autoSnakeCaseNames: options.config['auto_snake_case_names'] != false)
  ], 'angel_orm');
}

TypeReference futureOf(String type) {
  return TypeReference((b) => b
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
      var ctx = await buildOrmContext({}, element, annotation, buildStep,
          buildStep.resolver, autoSnakeCaseNames);
      var lib = buildOrmLibrary(buildStep.inputId, ctx);
      return lib.accept(DartEmitter()).toString();
    } else {
      throw 'The @Orm() annotation can only be applied to classes.';
    }
  }

  Library buildOrmLibrary(AssetId inputId, OrmBuildContext ctx) {
    return Library((lib) {
      // Create `FooQuery` class
      // Create `FooQueryWhere` class
      lib.body.add(buildQueryClass(ctx));
      lib.body.add(buildWhereClass(ctx));
      lib.body.add(buildValuesClass(ctx));
    });
  }

  Class buildQueryClass(OrmBuildContext ctx) {
    return Class((clazz) {
      var rc = ctx.buildContext.modelClassNameRecase;
      var queryWhereType = refer('${rc.pascalCase}QueryWhere');
      clazz
        ..name = '${rc.pascalCase}Query'
        ..extend = TypeReference((b) {
          b
            ..symbol = 'Query'
            ..types.addAll([
              ctx.buildContext.modelClassType,
              queryWhereType,
            ]);
        });

      // Override casts so that we can cast doubles
      clazz.methods.add(Method((b) {
        b
          ..name = 'casts'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = Block((b) {
            var args = <String, Expression>{};

            for (var field in ctx.effectiveFields) {
              var name = ctx.buildContext.resolveFieldName(field.name);
              var type = ctx.columns[field.name]?.type;
              if (type == null) continue;
              if (floatTypes.contains(type)) {
                args[name] = literalString('text');
              }
            }

            b.addExpression(literalMap(args).returned);
          });
      }));

      // Add values
      clazz.fields.add(Field((b) {
        var type = refer('${rc.pascalCase}QueryValues');
        b
          ..name = 'values'
          ..modifier = FieldModifier.final$
          ..annotations.add(refer('override'))
          ..type = type
          ..assignment = type.newInstance([]).code;
      }));

      // Add tableName
      clazz.methods.add(Method((m) {
        m
          ..name = 'tableName'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = Block((b) {
            b.addExpression(literalString(ctx.tableName).returned);
          });
      }));

      // Add fields getter
      clazz.methods.add(Method((m) {
        m
          ..name = 'fields'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = Block((b) {
            var names = ctx.effectiveFields
                .map((f) =>
                    literalString(ctx.buildContext.resolveFieldName(f.name)))
                .toList();
            b.addExpression(literalConstList(names).returned);
          });
      }));

      // Add _where member
      clazz.fields.add(Field((b) {
        b
          ..name = '_where'
          ..type = queryWhereType;
      }));

      // Add where getter
      clazz.methods.add(Method((b) {
        b
          ..name = 'where'
          ..type = MethodType.getter
          ..returns = queryWhereType
          ..annotations.add(refer('override'))
          ..body = Block((b) => b.addExpression(refer('_where').returned));
      }));
      // newWhereClause()
      clazz.methods.add(Method((b) {
        b
          ..name = 'newWhereClause'
          ..annotations.add(refer('override'))
          ..returns = queryWhereType
          ..body = Block((b) => b.addExpression(
              queryWhereType.newInstance([refer('this')]).returned));
      }));

      // Add deserialize()
      clazz.methods.add(Method((m) {
        m
          ..name = 'parseRow'
          ..static = true
          ..returns = ctx.buildContext.modelClassType
          ..requiredParameters.add(Parameter((b) => b
            ..name = 'row'
            ..type = refer('List')))
          ..body = Block((b) {
            int i = 0;
            var args = <String, Expression>{};

            for (var field in ctx.effectiveFields) {
              var fType = field.type;
              Reference type = convertTypeReference(field.type);
              if (isSpecialId(ctx, field)) type = refer('int');

              var expr = (refer('row').index(literalNum(i++)));
              if (isSpecialId(ctx, field)) {
                expr = expr.property('toString').call([]);
              } else if (field is RelationFieldImpl) {
                continue;
              } else if (ctx.columns[field.name]?.type == ColumnType.json) {
                expr = refer('json')
                    .property('decode')
                    .call([expr.asA(refer('String'))]).asA(type);
              } else if (floatTypes.contains(ctx.columns[field.name]?.type)) {
                expr = refer('double')
                    .property('tryParse')
                    .call([expr.property('toString').call([])]);
              } else if (fType is InterfaceType && fType.element.isEnum) {
                var isNull = expr.equalTo(literalNull);
                expr = isNull.conditional(literalNull,
                    type.property('values').index(expr.asA(refer('int'))));
              } else {
                expr = expr.asA(type);
              }

              args[field.name] = expr;
            }

            b.statements
                .add(Code('if (row.every((x) => x == null)) return null;'));
            b.addExpression(ctx.buildContext.modelClassType
                .newInstance([], args).assignVar('model'));

            ctx.relations.forEach((name, relation) {
              if (!const [
                RelationshipType.hasOne,
                RelationshipType.belongsTo,
                RelationshipType.hasMany
              ].contains(relation.type)) return;
              var foreign = relation.foreign;
              var skipToList = refer('row')
                  .property('skip')
                  .call([literalNum(i)])
                  .property('take')
                  .call([literalNum(relation.foreign.effectiveFields.length)])
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
              var block =
                  Block((b) => b.addExpression(refer('model').assign(expr)));
              var blockStr = block.accept(DartEmitter());
              var ifStr = 'if (row.length > $i) { $blockStr }';
              b.statements.add(Code(ifStr));
              i += relation.foreign.effectiveFields.length;
            });

            b.addExpression(refer('model').returned);
          });
      }));

      clazz.methods.add(Method((m) {
        m
          ..name = 'deserialize'
          ..annotations.add(refer('override'))
          ..requiredParameters.add(Parameter((b) => b
            ..name = 'row'
            ..type = refer('List')))
          ..body = Block((b) {
            b.addExpression(refer('parseRow').call([refer('row')]).returned);
          });
      }));

      // If there are any relations, we need some overrides.
      clazz.constructors.add(Constructor((b) {
        b
          ..optionalParameters.add(Parameter((b) => b
            ..named = true
            ..name = 'parent'
            ..type = refer('Query')))
          ..optionalParameters.add(Parameter((b) => b
            ..named = true
            ..name = 'trampoline'
            ..type = TypeReference((b) => b
              ..symbol = 'Set'
              ..types.add(refer('String')))))
          ..initializers.add(Code('super(parent: parent)'))
          ..body = Block((b) {
            b.statements.addAll([
              Code('trampoline ??= Set();'),
              Code('trampoline.add(tableName);'),
            ]);

            // Add any manual SQL expressions.
            ctx.columns.forEach((name, col) {
              if (col != null && col.hasExpression) {
                var lhs = refer('expressions').index(
                    literalString(ctx.buildContext.resolveFieldName(name)));
                var rhs = literalString(col.expression);
                b.addExpression(lhs.assign(rhs));
              }
            });

            // Add a constructor that initializes _where
            b.addExpression(
              refer('_where')
                  .assign(queryWhereType.newInstance([refer('this')])),
            );

            // Note: this is where subquery fields for relations are added.
            ctx.relations.forEach((fieldName, relation) {
              //var name = ctx.buildContext.resolveFieldName(fieldName);
              if (relation.type == RelationshipType.belongsTo ||
                  relation.type == RelationshipType.hasOne ||
                  relation.type == RelationshipType.hasMany) {
                var foreign = relation.throughContext ?? relation.foreign;

                // If this is a many-to-many, add the fields from the other object.

                var additionalStrs = relation.foreign.effectiveFields.map((f) =>
                    relation.foreign.buildContext.resolveFieldName(f.name));
                var additionalFields = additionalStrs.map(literalString);

                var joinArgs = [relation.localKey, relation.foreignKey]
                    .map(literalString)
                    .toList();

                // In the case of a many-to-many, we don't generate a subquery field,
                // as it easily leads to stack overflows.
                if (relation.isManyToMany) {
                  // We can't simply join against the "through" table; this itself must
                  // be a join.
                  // (SELECT role_users.role_id, <user_fields>
                  // FROM users
                  // LEFT JOIN role_users ON role_users.user_id=users.id)
                  var foreignFields = additionalStrs
                      .map((f) => '${relation.foreign.tableName}.$f');
                  var b = StringBuffer('(SELECT ');
                  // role_users.role_id
                  b.write('${relation.throughContext.tableName}');
                  b.write('.${relation.foreignKey}');
                  // , <user_fields>
                  b.write(foreignFields.isEmpty
                      ? ''
                      : ', ' + foreignFields.join(', '));
                  // FROM users
                  b.write(' FROM ');
                  b.write(relation.foreign.tableName);
                  // LEFT JOIN role_users
                  b.write(' LEFT JOIN ${relation.throughContext.tableName}');
                  // Figure out which field on the "through" table points to users (foreign).
                  var throughRelation =
                      relation.throughContext.relations.values.firstWhere((e) {
                    return e.foreignTable == relation.foreign.tableName;
                  }, orElse: () {
                    // _Role has a many-to-many to _User through _RoleUser, but
                    // _RoleUser has no relation pointing to _User.
                    var b = StringBuffer();
                    b.write(ctx.buildContext.modelClassName);
                    b.write('has a many-to-many relationship to ');
                    b.write(relation.foreign.buildContext.modelClassName);
                    b.write(' through ');
                    b.write(
                        relation.throughContext.buildContext.modelClassName);
                    b.write(', but ');
                    b.write(
                        relation.throughContext.buildContext.modelClassName);
                    b.write('has no relation pointing to ');
                    b.write(relation.foreign.buildContext.modelClassName);
                    b.write('.');
                    throw b.toString();
                  });

                  // ON role_users.user_id=users.id)
                  b.write(' ON ');
                  b.write('${relation.throughContext.tableName}');
                  b.write('.');
                  b.write(throughRelation.localKey);
                  b.write('=');
                  b.write(relation.foreign.tableName);
                  b.write('.');
                  b.write(throughRelation.foreignKey);
                  b.write(')');

                  joinArgs.insert(0, literalString(b.toString()));
                } else {
                  // In the past, we would either do a join on the table name
                  // itself, or create an instance of a query.
                  //
                  // From this point on, however, we will create a field for each
                  // join, so that users can customize the generated query.
                  //
                  // There'll be a private `_field`, and then a getter, named `field`,
                  // that returns the subquery object.
                  var foreignQueryType = refer(
                      foreign.buildContext.modelClassNameRecase.pascalCase +
                          'Query');
                  clazz
                    ..fields.add(Field((b) => b
                      ..name = '_$fieldName'
                      ..type = foreignQueryType))
                    ..methods.add(Method((b) => b
                      ..name = fieldName
                      ..type = MethodType.getter
                      ..returns = foreignQueryType
                      ..body = refer('_$fieldName').returned.statement));

                  // Assign a value to `_field`.
                  var queryInstantiation = foreignQueryType.newInstance([], {
                    'trampoline': refer('trampoline'),
                    'parent': refer('this')
                  });
                  joinArgs.insert(
                      0, refer('_$fieldName').assign(queryInstantiation));
                }

                var joinType = relation.joinTypeString;
                b.addExpression(refer(joinType).call(joinArgs, {
                  'additionalFields':
                      literalConstList(additionalFields.toList()),
                  'trampoline': refer('trampoline'),
                }));
              }
            });
          });
      }));

      // If we have any many-to-many relations, we need to prevent
      // fetching this table within their joins.
      var manyToMany = ctx.relations.entries.where((e) => e.value.isManyToMany);

      if (manyToMany.isNotEmpty) {
        var outExprs = manyToMany.map<Expression>((e) {
          var foreignTableName = e.value.throughContext.tableName;
          return CodeExpression(Code('''
          (!(
            trampoline.contains('${ctx.tableName}')
            && trampoline.contains('$foreignTableName')
          ))
          '''));
        });
        var out = outExprs.reduce((a, b) => a.and(b));

        clazz.methods.add(Method((b) {
          b
            ..name = 'canCompile'
            ..annotations.add(refer('override'))
            ..requiredParameters.add(Parameter((b) => b..name = 'trampoline'))
            ..returns = refer('bool')
            ..body = Block((b) {
              b.addExpression(out.returned);
            });
        }));
      }

      // Also, if there is a @HasMany, generate overrides for query methods that
      // execute in a transaction, and invoke fetchLinked.
      if (ctx.relations.values.any((r) => r.type == RelationshipType.hasMany)) {
        for (var methodName in const ['get', 'update', 'delete']) {
          clazz.methods.add(Method((b) {
            var type = ctx.buildContext.modelClassType.accept(DartEmitter());
            b
              ..name = methodName
              ..annotations.add(refer('override'))
              ..requiredParameters.add(Parameter((b) => b
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

            var keyName =
                findPrimaryFieldInList(ctx, ctx.buildContext.fields)?.name;
            if (keyName == null) {
              throw '${ctx.buildContext.originalClassName} has no defined primary key.\n'
                  '@HasMany and @ManyToMany relations require a primary key to be defined on the model.';
            }

            b.body = Code('''
                    return super.$methodName(executor).then((result) {
                      return result.fold<List<$type>>([], (out, model) {
                        var idx = out.indexWhere((m) => m.$keyName == model.$keyName);

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

  Class buildWhereClass(OrmBuildContext ctx) {
    return Class((clazz) {
      var rc = ctx.buildContext.modelClassNameRecase;
      clazz
        ..name = '${rc.pascalCase}QueryWhere'
        ..extend = refer('QueryWhere');

      // Build expressionBuilders getter
      clazz.methods.add(Method((m) {
        m
          ..name = 'expressionBuilders'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..body = Block((b) {
            var references =
                ctx.effectiveNormalFields.map((f) => refer(f.name));
            b.addExpression(literalList(references).returned);
          });
      }));

      var initializers = <Code>[];

      // Add builders for each field
      for (var field in ctx.effectiveNormalFields) {
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
          builderType = TypeReference((b) => b
            ..symbol = 'NumericSqlExpressionBuilder'
            ..types.add(refer(isSpecialId(ctx, field) ? 'int' : type.name)));
        } else if (type is InterfaceType && type.element.isEnum) {
          builderType = TypeReference((b) => b
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
          if (relation.type != RelationshipType.belongsTo) {
            continue;
          } else {
            builderType = TypeReference((b) => b
              ..symbol = 'NumericSqlExpressionBuilder'
              ..types.add(refer('int')));
            name = relation.localKey;
          }
        } else {
          throw UnsupportedError(
              'Cannot generate ORM code for field of type ${field.type.name}.');
        }

        clazz.fields.add(Field((b) {
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
      clazz.constructors.add(Constructor((b) {
        b
          ..requiredParameters.add(Parameter((b) => b
            ..name = 'query'
            ..type = refer('${rc.pascalCase}Query')))
          ..initializers.addAll(initializers);
      }));
    });
  }

  Class buildValuesClass(OrmBuildContext ctx) {
    return Class((clazz) {
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
              var type = ctx.columns[field.name]?.type;
              if (type == null) continue;
              if (const TypeChecker.fromRuntime(List)
                  .isAssignableFromType(fType)) {
                args[name] = literalString(type.name);
              } else if (floatTypes.contains(type)) {
                args[name] = literalString(type.name);
              }
            }

            b.addExpression(literalMap(args).returned);
          });
      }));

      // Each field generates a getter and setter
      for (var field in ctx.effectiveNormalFields) {
        var fType = field.type;
        var name = ctx.buildContext.resolveFieldName(field.name);
        var type = convertTypeReference(field.type);

        clazz.methods.add(Method((b) {
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
          } else if (floatTypes.contains(ctx.columns[field.name]?.type)) {
            value = refer('double')
                .property('tryParse')
                .call([value.asA(refer('String'))]);
          } else {
            value = value.asA(type);
          }

          b
            ..name = field.name
            ..type = MethodType.getter
            ..returns = type
            ..body = Block((b) => b.addExpression(value.returned));
        }));

        clazz.methods.add(Method((b) {
          Expression value = refer('value');

          if (fType is InterfaceType && fType.element.isEnum) {
            value = CodeExpression(Code('value?.index'));
          } else if (const TypeChecker.fromRuntime(List)
              .isAssignableFromType(fType)) {
            value = refer('json').property('encode').call([value]);
          } else if (floatTypes.contains(ctx.columns[field.name]?.type)) {
            value = value.property('toString').call([]);
          }

          b
            ..name = field.name
            ..type = MethodType.setter
            ..requiredParameters.add(Parameter((b) => b
              ..name = 'value'
              ..type = type))
            ..body =
                refer('values').index(literalString(name)).assign(value).code;
        }));
      }

      // Add an copyFrom(model)
      clazz.methods.add(Method((b) {
        b
          ..name = 'copyFrom'
          ..returns = refer('void')
          ..requiredParameters.add(Parameter((b) => b
            ..name = 'model'
            ..type = ctx.buildContext.modelClassType))
          ..body = Block((b) {
            for (var field in ctx.effectiveNormalFields) {
              if (isSpecialId(ctx, field) || field is RelationFieldImpl) {
                continue;
              }
              b.addExpression(refer(field.name)
                  .assign(refer('model').property(field.name)));
            }

            for (var field in ctx.effectiveNormalFields) {
              if (field is RelationFieldImpl) {
                var original = field.originalFieldName;
                var prop = refer('model').property(original);
                // Add only if present
                var target = refer('values').index(literalString(
                    ctx.buildContext.resolveFieldName(field.name)));
                var foreign = field.relationship.throughContext ??
                    field.relationship.foreign;
                var foreignField = field.relationship.findForeignField(ctx);
                var parsedId = prop.property(foreignField.name);

                if (isSpecialId(foreign, field)) {
                  parsedId =
                      (refer('int').property('tryParse').call([parsedId]));
                }

                var cond = prop.notEqualTo(literalNull);
                var condStr = cond.accept(DartEmitter());
                var blkStr =
                    Block((b) => b.addExpression(target.assign(parsedId)))
                        .accept(DartEmitter());
                var ifStmt = Code('if ($condStr) { $blkStr }');
                b.statements.add(ifStmt);
              }
            }
          });
      }));
    });
  }
}
