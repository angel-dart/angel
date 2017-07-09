import 'dart:async';
import 'dart:mirrors';
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
import 'package:source_gen/source_gen.dart';
import 'package:query_builder_sql/query_builder_sql.dart';
import '../annotations.dart';

// TODO: whereXLessThan, greaterThan, etc.

final RegExp _leadingDot = new RegExp(r'^\.+');

const List<String> QUERY_DO_NOT_OVERRIDE = const ['when'];

typedef Iterable<ExpressionBuilder> SuperArgumentProvider(
    ORM model, ClassElement clazz);

class AngelQueryBuilderGenerator extends GeneratorForAnnotation<ORM> {
  ClassMirror _baseRepositoryClassMirror;
  final List<String> _imports = [
    'dart:async',
    'package:query_builder/query_builder.dart'
  ];

  final Map<String, TypeBuilder> _constructorParams = {};
  SuperArgumentProvider _superArgProvider;

  AngelQueryBuilderGenerator(Type baseRepositoryQueryClass,
      {Iterable<String> additonalImports: const [],
        Map<String, TypeBuilder> constructorParams: const {},
        SuperArgumentProvider superArgProvider}) {
    _baseRepositoryClassMirror = reflectClass(baseRepositoryQueryClass);
    _imports.addAll(additonalImports ?? []);
    _constructorParams.addAll(constructorParams ?? {});
    _superArgProvider = superArgProvider ??
            (annotation, clazz) => [
          literal(annotation.tableName?.isNotEmpty == true
              ? annotation.tableName
              : pluralize(new ReCase(clazz.name.substring(1)).snakeCase))
        ];
  }

  factory AngelQueryBuilderGenerator.postgresql() =>
      new AngelQueryBuilderGenerator(SqlRepositoryQuery, constructorParams: {
        'connection': new TypeBuilder('PostgreSQLConnection')
      }, additonalImports: [
        'package:postgres/postgres.dart',
        'package:query_builder_sql/query_builder_sql.dart'
      ]);

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ORM annotation, BuildStep buildStep) async {
    if (element.kind != ElementKind.CLASS)
      throw 'Only classes may be annotated with @model.';
    var lib = generatePostgresLibrary(element, annotation, buildStep.inputId);
    return prettyToSource(lib.buildAst());
  }

  LibraryBuilder generatePostgresLibrary(
      ClassElement clazz, ORM annotation, AssetId inputId) {
    if (!clazz.name.startsWith('_'))
      throw 'Classes annotated with @model must have names starting with an underscore.';
    var lib = new LibraryBuilder();
    lib.addDirectives(_imports.map((p) => new ImportBuilder(p)));
    lib.addDirective(new ImportBuilder(p.basename(inputId.path)));

    // Find all aliases...
    Map<String, String> aliases = {};
    clazz.fields.forEach((field) {
      var aliasAnnotation = field.metadata
          .firstWhere((ann) => matchAnnotation(Alias, ann), orElse: () => null);
      if (aliasAnnotation != null) {
        var alias = instantiateAnnotation(aliasAnnotation) as Alias;
        aliases[field.name] = alias.name;
      }
    });

    lib.addMember(generateRepositoryClass(clazz, aliases));
    lib.addMember(generateRepositoryQueryClass(clazz, annotation, aliases));
    return lib;
  }

  ClassBuilder generateRepositoryClass(
      ClassElement clazz, Map<String, String> aliases) {
    var genClassName = clazz.name.substring(1) + 'Repository';
    var genQueryClassName = genClassName + 'Query';
    var genClass = new ClassBuilder(genClassName);
    var genQueryType = new TypeBuilder(genQueryClassName);

    // Add `connection` field + constructor

    var genConstructor = new ConstructorBuilder();
    _constructorParams.forEach((name, type) {
      genClass.addField(varFinal(name, type: type));
      genConstructor.addPositional(parameter(name), asField: true);
    });
    genClass.addConstructor(genConstructor);

    // Add an all method
    genClass.addMethod(new MethodBuilder('all',
        returnType: new TypeBuilder(genQueryClassName),
        returns: new TypeBuilder(genQueryClassName)
            .newInstance([reference('connection')])));

    // For each field, add a whereX() method...
    clazz.fields
        .map((field) => generateWhereFieldMethod(
        field, reference('all').call([]), genQueryType, aliases))
        .forEach(genClass.addMethod);
    return genClass;
  }

  ClassBuilder generateRepositoryQueryClass(
      ClassElement clazz, ORM annotation, Map<String, String> aliases) {
    var modelClassName = clazz.name.substring(1);
    var genClassName = clazz.name.substring(1) + 'RepositoryQuery';
    var genClass = new ClassBuilder(genClassName,
        asExtends: new TypeBuilder(
            MirrorSystem.getName(_baseRepositoryClassMirror.simpleName),
            genericTypes: [new TypeBuilder(modelClassName)]));
    var genQueryType = new TypeBuilder(genClassName);

    // Add `connection` field + constructor

    var genConstructor = new ConstructorBuilder(
        invokeSuper: _superArgProvider(annotation, clazz));
    _constructorParams.forEach((name, type) {
      genClass.addField(varFinal(name, type: type));
      genConstructor.addPositional(parameter(name), asField: true);
    });
    genClass.addConstructor(genConstructor);

    // For each field, add a whereX() method...
    clazz.fields
        .map((field) => generateWhereFieldMethod(
        field, explicitThis, genQueryType, aliases))
        .forEach(genClass.addMethod);

    // Add orWhereX()
    clazz.fields
        .map((f) => generateOrWhereFieldMethod(genQueryType, f))
        .forEach(genClass.addMethod);

    // Override any query methods
    _baseRepositoryClassMirror.instanceMembers.forEach((sym, method) {
      // Skip setters, etc.
      if (!method.isRegularMethod) return;

      // Only if return type contains 'RepositoryQuery'
      var methodName = MirrorSystem.getName(sym);

      if (QUERY_DO_NOT_OVERRIDE.contains(methodName)) return;

      var returnTypeName = MirrorSystem.getName(method.returnType.simpleName);

      if (returnTypeName.contains('RepositoryQuery')) {
        var overriddenMethod =
        new MethodBuilder(methodName, returnType: genQueryType);
        // Add @override
        overriddenMethod.addAnnotation(lib$core.override);

        // Find all positional and named args
        List<String> args = [];
        List<String> named = [];

        method.parameters.forEach((param) {
          var paramName = MirrorSystem.getName(param.simpleName);
          var typeName = MirrorSystem.getName(param.type.simpleName);
          var paramType = new TypeBuilder(typeName);
          var genParam = parameter(paramName, [paramType]);

          if (!param.isNamed) {
            args.add(paramName);
            overriddenMethod.addPositional(
                param.isOptional ? genParam.asOptional() : genParam);
          } else {
            overriddenMethod.addNamed(genParam);
            named.add(paramName);
          }
        });

        // Invoke super
        overriddenMethod.addStatement(reference('super')
            .invoke(methodName, args.map(reference),
            namedArguments: named.fold<Map<String, ExpressionBuilder>>(
                {}, (out, k) => out..[k] = reference(k)))
            .asReturn());

        genClass.addMethod(overriddenMethod);
      }
    });

    // Override toSql to put keys in desired order
    // TODO: Override toSql

    // Add get()
    genClass.addMethod(generateGetMethod(clazz, modelClassName, aliases));

    return genClass;
  }

  MethodBuilder generateGetMethod(
      ClassElement clazz, String modelClassName, Map<String, String> aliases) {
    var meth = new MethodBuilder('get')..addAnnotation(lib$core.override);

    // Map rows to model...
    var mapRowsToModel = new MethodBuilder.closure()
      ..addPositional(parameter('rows'));

    // First, figure out which rows we fetched...
    //
    // var requestedKeys = whereFields.keys.isNotEmpty ? whereFields.keys : [<all fields...>];

    //var allModelFields = clazz.fields
    //    .map((f) => aliases.containsKey(f.name) ? aliases[f.name] : f.name);
    //var whereFieldsKeys = reference('whereFields').property('keys');

    // return new Stream<>.fromFuture(...)
    meth.addStatement(lib$async.Stream.newInstance([
      reference('connection')
          .invoke('query', [reference('toSql').call([])]).invoke(
          'then', [mapRowsToModel])
    ], constructor: 'fromFuture').asReturn());

    return meth;
  }

  MethodBuilder generateWhereFieldMethod(
      FieldElement field,
      ExpressionBuilder baseQuery,
      TypeBuilder returnType,
      Map<String, String> aliases) {
    var rc = new ReCase(field.name);
    var whereMethod =
    new MethodBuilder('where${rc.pascalCase}', returnType: returnType);
    var columnName =
    aliases.containsKey(field.name) ? aliases[field.name] : field.name;
    whereMethod.addPositional(
        parameter(field.name, [new TypeBuilder(field.type.displayName)]));

    if (field.type.name == 'DateTime') {
      // Add named `{time: true}`
      whereMethod.addNamed(
          parameter('time', [lib$core.bool]).asOptional(literal(true)));
      // return all().whereDate('x', x, time: time != false);
      // return all().where('x', x);
      whereMethod.addStatement(baseQuery.invoke('whereDate', [
        literal(columnName),
        reference(field.name)
      ], namedArguments: {
        'time': reference('time').notEquals(literal(false))
      }).asReturn());
    } else {
      // return all().where('x', x);
      whereMethod.addStatement(baseQuery.invoke(
          'where', [literal(columnName), reference(field.name)]).asReturn());
    }

    return whereMethod;
  }

  MethodBuilder generateOrWhereFieldMethod(
      TypeBuilder genQueryClassType, FieldElement field) {
    var rc = new ReCase(field.name);
    var orWhereMethod = new MethodBuilder('orWhere' + rc.pascalCase,
        returnType: genQueryClassType);
    orWhereMethod.addPositional(
        parameter(field.name, [new TypeBuilder(field.type.displayName)]));

    if (field.type.name == 'DateTime') {
      orWhereMethod.addNamed(parameter('time', [lib$core.bool]));
      orWhereMethod.addStatement(reference('or').call([
        reference('where' + rc.pascalCase).call([
          reference(field.name)
        ], namedArguments: {
          'time': reference('time').notEquals(literal(false))
        })
      ]).asReturn());
    } else {
      orWhereMethod.addStatement(reference('or').call([
        reference('where' + rc.pascalCase).call([reference(field.name)])
      ]).asReturn());
    }

    return orWhereMethod;
  }
}
