import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
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
import 'build_context.dart';
import 'postgres_build_context.dart';

class PostgresServiceGenerator extends GeneratorForAnnotation<ORM> {
  final bool autoSnakeCaseNames;

  final bool autoIdAndDateFields;

  const PostgresServiceGenerator(
      {this.autoSnakeCaseNames: true, this.autoIdAndDateFields: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ORM annotation, BuildStep buildStep) async {
    if (buildStep.inputId.path.contains('.service.g.dart')) {
      return null;
    }

    if (element is! ClassElement)
      throw 'Only classes can be annotated with @ORM().';
    var resolver = await buildStep.resolver;
    var lib =
        generateOrmLibrary(element.library, resolver, buildStep).buildAst();
    if (lib == null) return null;
    return prettyToSource(lib);
  }

  LibraryBuilder generateOrmLibrary(
      LibraryElement libraryElement, Resolver resolver, BuildStep buildStep) {
    var lib = new LibraryBuilder();
    lib.addDirective(new ImportBuilder('dart:async'));
    lib.addDirective(
        new ImportBuilder('package:angel_framework/angel_framework.dart'));
    lib.addDirective(new ImportBuilder('package:postgres/postgres.dart'));
    lib.addDirective(new ImportBuilder(p.basename(buildStep.inputId.path)));

    var pathName = p.basenameWithoutExtension(
        p.basenameWithoutExtension(buildStep.inputId.path));
    lib.addDirective(new ImportBuilder('$pathName.orm.g.dart'));

    var elements = getElementsFromLibraryElement(libraryElement)
        .where((el) => el is ClassElement);
    Map<ClassElement, PostgresBuildContext> contexts = {};
    List<String> done = [];

    for (var element in elements) {
      if (!done.contains(element.name)) {
        var ann = element.metadata
            .firstWhere((a) => matchAnnotation(ORM, a), orElse: () => null);
        if (ann != null) {
          contexts[element] = buildContext(
              element,
              instantiateAnnotation(ann),
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

    var params = reference('params'),
        buildQuery = reference('buildQuery'),
        connection = reference('connection'),
        query = reference('query');

    // Future<List<T>> index([p]) => buildQuery(p).get(connection).toList();
    clazz.addMethod(lambda(
        'index',
        buildQuery
            .call([params]).invoke('get', [connection]).invoke('toList', []),
        returnType: new TypeBuilder('Future', genericTypes: [
          new TypeBuilder('List', genericTypes: [ctx.modelClassBuilder])
        ]))
      ..addPositional(parameter('params', [lib$core.Map]))
      ..addAnnotation(lib$core.override));

    var read = new MethodBuilder('read',
        returnType:
            new TypeBuilder('Future', genericTypes: [ctx.modelClassBuilder]));
    parseParams(read, ctx, id: true);
    read.addStatement(query.invoke('get', [connection]).property('first'));
    clazz.addMethod(read);

    

    return clazz;
  }

  MethodBuilder buildQueryMethod(PostgresBuildContext ctx) {
    var meth =
        new MethodBuilder('buildQuery', returnType: ctx.queryClassBuilder);
    return meth;
  }

  MethodBuilder buildToIdMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('toId', returnType: lib$core.int);
    var id = reference('id');

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

  void parseParams(MethodBuilder meth, PostgresBuildContext ctx, {bool id}) {
    meth.addStatement(varField('query',
        value: reference('buildQuery').call([
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
}
