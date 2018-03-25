import 'dart:async';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart' hide LibraryBuilder;
import 'build_context.dart';
import 'postgres_build_context.dart';

class PostgresServiceGenerator extends GeneratorForAnnotation<ORM> {
  static const List<TypeChecker> primitives = const [
    const TypeChecker.fromRuntime(String),
    const TypeChecker.fromRuntime(int),
    const TypeChecker.fromRuntime(bool),
    const TypeChecker.fromRuntime(double),
    const TypeChecker.fromRuntime(num),
  ];

  static final ExpressionBuilder id = reference('id'),
      params = reference('params'),
      connection = reference('connection'),
      query = reference('query'),
      buildQuery = reference('buildQuery'),
      applyData = reference('applyData'),
      where = reference('query').property('where'),
      toId = reference('toId'),
      data = reference('data');

  final bool autoSnakeCaseNames;

  final bool autoIdAndDateFields;

  const PostgresServiceGenerator(
      {this.autoSnakeCaseNames: true, this.autoIdAndDateFields: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (buildStep.inputId.path.contains('.service.g.dart')) {
      return null;
    }

    if (element is! ClassElement)
      throw 'Only classes can be annotated with @ORM().';
    var resolver = await buildStep.resolver;
    var lib = await generateOrmLibrary(element.library, resolver, buildStep)
        .then((l) => l.buildAst());
    if (lib == null) return null;
    return prettyToSource(lib);
  }

  Future<LibraryBuilder> generateOrmLibrary(LibraryElement libraryElement,
      Resolver resolver, BuildStep buildStep) async {
    var lib = new LibraryBuilder();
    lib.addDirective(new ImportBuilder('dart:async'));
    lib.addDirective(
        new ImportBuilder('package:angel_framework/angel_framework.dart'));
    lib.addDirective(new ImportBuilder('package:postgres/postgres.dart'));
    lib.addDirective(new ImportBuilder(p.basename(buildStep.inputId.path)));

    var pathName = p.basenameWithoutExtension(
        p.basenameWithoutExtension(buildStep.inputId.path));
    lib.addDirective(new ImportBuilder('$pathName.orm.g.dart'));

    var elements = libraryElement.definingCompilationUnit.unit.declarations
        .where((el) => el is ClassDeclaration);
    Map<ClassElement, PostgresBuildContext> contexts = {};
    List<String> done = [];

    for (ClassDeclaration element in elements) {
      if (!done.contains(element.name)) {
        var ann = ormTypeChecker.firstAnnotationOf(element.element);
        if (ann != null) {
          contexts[element.element] = await buildContext(
              element.element,
              reviveOrm(new ConstantReader(ann)),
              buildStep,
              resolver,
              autoSnakeCaseNames != false,
              autoIdAndDateFields != false);
        }
      }
    }

    if (contexts.isEmpty) return null;

    done.clear();
    for (var element in contexts.keys) {
      if (!done.contains(element.name)) {
        var ctx = contexts[element];
        lib.addMember(buildServiceClass(ctx));
        done.add(element.name);
      }
    }
    return lib;
  }

  ClassBuilder buildServiceClass(PostgresBuildContext ctx) {
    var rc = new ReCase(ctx.modelClassName);
    var clazz = new ClassBuilder('${rc.pascalCase}Service',
        asExtends: new TypeBuilder('Service'));

    // Add fields
    // connection, allowRemoveAll, allowQuery

    clazz
      ..addField(varFinal('connection', type: ctx.postgreSQLConnectionBuilder))
      ..addField(varFinal('allowRemoveAll', type: lib$core.bool))
      ..addField(varFinal('allowQuery', type: lib$core.bool));

    clazz.addConstructor(constructor([
      thisField(parameter('connection')),
      thisField(named(parameter('allowRemoveAll', [literal(false)]))),
      thisField(named(parameter('allowQuery', [literal(false)])))
    ]));

    clazz.addMethod(buildQueryMethod(ctx));
    clazz.addMethod(buildToIdMethod(ctx));
    clazz.addMethod(buildApplyDataMethod(ctx));

    clazz.addMethod(buildIndexMethod(ctx));
    clazz.addMethod(buildCreateMethod(ctx));
    clazz.addMethod(buildReadOrDeleteMethod('read', 'get', ctx));
    clazz.addMethod(buildReadOrDeleteMethod('remove', 'delete', ctx));
    clazz.addMethod(buildUpdateMethod(ctx));
    clazz.addMethod(buildModifyMethod(ctx));

    return clazz;
  }

  MethodBuilder buildQueryMethod(PostgresBuildContext ctx) {
    var meth =
        new MethodBuilder('buildQuery', returnType: ctx.queryClassBuilder)
          ..addPositional(parameter('params', [lib$core.Map]));
    var paramQuery = params[literal('query')];
    meth.addStatement(
        varField('query', value: ctx.queryClassBuilder.newInstance([])));
    var ifStmt = ifThen(paramQuery.isInstanceOf(lib$core.Map));

    ctx.fields.forEach((f) {
      var alias = ctx.resolveFieldName(f.name);
      var queryKey = paramQuery[literal(alias)];

      if (f.type.isDynamic ||
          f.type.isObject ||
          f.type.isObject ||
          primitives.any((t) => t.isAssignableFromType(f.type))) {
        ifStmt
            .addStatement(where.property(f.name).invoke('equals', [queryKey]));
      } else if (dateTimeTypeChecker.isAssignableFromType(f.type)) {
        var dt = queryKey
            .isInstanceOf(lib$core.String)
            .ternary(lib$core.DateTime.invoke('parse', [queryKey]), queryKey);
        ifStmt.addStatement(
            where.property(f.name).invoke('equals', [updatedAt(dt)]));
      } else {
        print(
            'Cannot compute service query binding for field "${f.name}" in ${ctx.originalClassName}');
      }
    });

    meth.addStatement(ifStmt);
    meth.addStatement(query.asReturn());
    return meth;
  }

  MethodBuilder buildToIdMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('toId', returnType: lib$core.int)
      ..addPositional(parameter('id'));

    meth.addStatement(ifThen(id.isInstanceOf(lib$core.int), [
      id.asReturn(),
      elseThen([
        ifThen(id.equals(literal('null')).or(id.equals(literal(null))), [
          literal(null).asReturn(),
          elseThen([
            lib$core.int.invoke('parse', [id.invoke('toString', [])]).asReturn()
          ])
        ])
      ])
    ]));

    return meth;
  }

  MethodBuilder buildIndexMethod(PostgresBuildContext ctx) {
    // Future<List<T>> index([p]) => buildQuery(p).get(connection).toList();
    return method('index', [
      new TypeBuilder('Future', genericTypes: [
        new TypeBuilder('List', genericTypes: [ctx.modelClassBuilder])
      ]),
      parameter('params', [lib$core.Map]).asOptional(),
      reference('buildQuery').call([params]).invoke('get', [connection]).invoke(
        'toList',
        [],
      ).asReturn(),
    ]);
  }

  MethodBuilder buildReadOrDeleteMethod(
      String name, String operation, PostgresBuildContext ctx) {
    var throw404 = new MethodBuilder.closure()..addPositional(parameter('_'));
    throw404.addStatement(new TypeBuilder('AngelHttpException').newInstance(
      [],
      constructor: 'notFound',
      named: {
        'message':
            literal('No record found for ID ') + id.invoke('toString', []),
      },
    ));

    return method(name, [
      new TypeBuilder('Future', genericTypes: [ctx.modelClassBuilder]),
      parameter('id'),
      parameter('params', [lib$core.Map]).asOptional(),
      varField('query', value: buildQuery.call([params])),
      where.property('id').invoke('equals', [
        toId.call([id])
      ]),
      query
          .invoke(operation, [connection])
          .property('first')
          .invoke('catchError', [
            throw404,
          ])
          .asReturn(),
    ]);
  }

  MethodBuilder buildApplyDataMethod(PostgresBuildContext ctx) {
    var meth =
        new MethodBuilder('applyData', returnType: ctx.modelClassBuilder);
    meth.addPositional(parameter('data'));

    meth.addStatement(ifThen(
      data.isInstanceOf(ctx.modelClassBuilder).or(data.equals(literal(null))),
      [
        data.asReturn(),
      ],
    ));

    var ifStmt = new IfStatementBuilder(data.isInstanceOf(lib$core.Map));
    ifStmt.addStatement(
        varField('query', value: ctx.modelClassBuilder.newInstance([])));

    applyFieldsToInstance(ctx, query, ifStmt.addStatement);

    ifStmt.addStatement(query.asReturn());

    ifStmt.setElse(
      new TypeBuilder('AngelHttpException')
          .newInstance([],
              constructor: 'badRequest',
              named: {'message': literal('Invalid data.')})
          .asThrow(),
    );

    meth.addStatement(ifStmt);

    return meth;
  }

  MethodBuilder buildCreateMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('create',
        returnType:
            new TypeBuilder('Future', genericTypes: [ctx.modelClassBuilder]));
    meth
      ..addPositional(parameter('data'))
      ..addPositional(parameter('params', [lib$core.Map]).asOptional());

    var rc = new ReCase(ctx.modelClassName);
    meth.addStatement(
      ctx.queryClassBuilder.invoke('insert${rc.pascalCase}', [
        connection,
        applyData.call([data])
      ]).asReturn(),
    );

    return meth;
  }

  MethodBuilder buildModifyMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('modify',
        modifier: MethodModifier.asAsync,
        returnType:
            new TypeBuilder('Future', genericTypes: [ctx.modelClassBuilder]));
    meth
      ..addPositional(parameter('id'))
      ..addPositional(parameter('data'))
      ..addPositional(parameter('params', [lib$core.Map]).asOptional());

    // read() by id
    meth.addStatement(varField(
      'query',
      value: reference('read').call(
        [
          toId.call([id]),
          params
        ],
      ).asAwait(),
    ));

    var rc = new ReCase(ctx.modelClassName);

    meth.addStatement(ifThen(data.isInstanceOf(ctx.modelClassBuilder), [
      data.asAssign(query),
    ]));

    var ifStmt = ifThen(data.isInstanceOf(lib$core.Map));

    applyFieldsToInstance(ctx, query, ifStmt.addStatement);
    meth.addStatement(ifStmt);
    meth.addStatement(
      ctx.queryClassBuilder
          .invoke('update${rc.pascalCase}', [connection, query])
          .asAwait()
          .asReturn(),
    );

    return meth;
  }

  MethodBuilder buildUpdateMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('update',
        returnType:
            new TypeBuilder('Future', genericTypes: [ctx.modelClassBuilder]));
    meth
      ..addPositional(parameter('id'))
      ..addPositional(parameter('data'))
      ..addPositional(parameter('params', [lib$core.Map]).asOptional());

    var rc = new ReCase(ctx.modelClassName);
    meth.addStatement(
      ctx.queryClassBuilder.invoke('update${rc.pascalCase}', [
        connection,
        applyData.call([data])
      ]).asReturn(),
    );

    return meth;
  }

  void parseParams(MethodBuilder meth, PostgresBuildContext ctx, {bool id}) {
    meth.addStatement(varField('query',
        value: buildQuery.call([
          reference('params')
              .notEquals(literal(null))
              .ternary(reference('params'), map({}))
        ])));

    if (id == true) {
      meth.addStatement(
          reference('query').property('where').property('id').invoke('equals', [
        reference('toId').call([reference('id')])
      ]));
    }
  }

  void applyFieldsToInstance(PostgresBuildContext ctx, ExpressionBuilder query,
      void addStatement(StatementBuilder statement)) {
    ctx.fields.forEach((f) {
      var alias = ctx.resolveFieldName(f.name);
      var dataKey = data[literal(alias)];
      ExpressionBuilder target;

      // Skip `id`
      if (autoIdAndDateFields != false && f.name == 'id') return;

      if (f.type.isDynamic ||
          f.type.isObject ||
          primitives.any((t) => t.isAssignableFromType(f.type))) {
        target = dataKey;
      } else if (dateTimeTypeChecker.isAssignableFromType(f.type)) {
        var dt = dataKey
            .isInstanceOf(lib$core.String)
            .ternary(lib$core.DateTime.invoke('parse', [dataKey]), dataKey);
        target = updatedAt(dt);
      } else {
        print(
            'Cannot compute service applyData() binding for field "${f.name}" in ${ctx.originalClassName}');
      }

      if (target != null) {
        addStatement(ifThen(data.invoke('containsKey', [literal(alias)]),
            [target.asAssign(query.property(f.name))]));
      }
    });
  }

  ExpressionBuilder updatedAt(ExpressionBuilder dt) {
    if (autoIdAndDateFields == false) return dt;
    return dt
        .notEquals(literal(null))
        .ternary(dt, lib$core.DateTime.newInstance([], constructor: 'now'));
  }
}
