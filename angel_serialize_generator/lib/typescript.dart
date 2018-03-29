part of angel_serialize_generator;

class TypeScriptDefinitionBuilder implements Builder {
  final bool autoSnakeCaseNames;

  const TypeScriptDefinitionBuilder({this.autoSnakeCaseNames: true});

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      '.dart': ['.d.ts']
    };
  }

  Future<String> compileToTypeScriptType(String fieldName, InterfaceType type,
      List<CodeBuffer> ext, BuildStep buildStep) async {
    String typeScriptType = 'any';

    var types = const {
      num: 'number',
      bool: 'boolean',
      String: 'string',
      Symbol: 'Symbol',
    };

    types.forEach((t, tsType) {
      if (new TypeChecker.fromRuntime(t).isAssignableFromType(type))
        typeScriptType = tsType;
    });

    if (isListModelType(type)) {
      var arg = await compileToTypeScriptType(
          fieldName, type.typeArguments[0], ext, buildStep);
      typeScriptType = '$arg[]';
    } else if (isMapToModelType(type)) {
      var key = await compileToTypeScriptType(
          fieldName, type.typeArguments[0], ext, buildStep);
      var value = await compileToTypeScriptType(
          fieldName, type.typeArguments[1], ext, buildStep);
      var modelType = type.typeArguments[1];
      var ctx = await buildContext(
        modelType.element,
        new ConstantReader(
            serializableTypeChecker.firstAnnotationOf(modelType.element)),
        buildStep,
        buildStep.resolver,
        autoSnakeCaseNames,
        true,
      );

      typeScriptType = ctx.modelClassNameRecase.pascalCase +
          new ReCase(fieldName).pascalCase;

      ext.add(new CodeBuffer()
        ..writeln('interface $typeScriptType {')
        ..indent()
        ..writeln('[key: $key]: $value;')
        ..outdent()
        ..writeln('}'));
    } else if (const TypeChecker.fromRuntime(List).isAssignableFromType(type)) {
      typeScriptType = 'any[]';
    } else if (isModelClass(type)) {
      var ctx = await buildContext(
        type.element,
        new ConstantReader(
            serializableTypeChecker.firstAnnotationOf(type.element)),
        buildStep,
        buildStep.resolver,
        autoSnakeCaseNames,
        true,
      );
      typeScriptType = ctx.modelClassNameRecase.pascalCase;
    }

    return typeScriptType;
  }

  @override
  Future build(BuildStep buildStep) async {
    var contexts = <BuildContext>[];
    var lib = new LibraryReader(await buildStep.inputLibrary);
    var elements =
        lib.annotatedWith(const TypeChecker.fromRuntime(Serializable));

    for (var element in elements) {
      if (element.element.kind != ElementKind.CLASS)
        throw 'Only classes can be annotated with a @Serializable() annotation.';

      contexts.add(await buildContext(
          element.element,
          element.annotation,
          buildStep,
          await buildStep.resolver,
          true,
          autoSnakeCaseNames != false));
    }

    if (contexts.isEmpty) return;

    var buf = new CodeBuffer(
      trailingNewline: true,
      sourceUrl: buildStep.inputId.uri,
    );

    // declare module `foo` {
    //buf
    //  ..writeln("declare module '${buildStep.inputId.package}' {")
    //  ..indent();

    for (var ctx in contexts) {
      // interface Bar { ... }
      buf
        ..writeln('interface ${ctx.modelClassNameRecase.pascalCase} {')
        ..indent();

      var ext = <CodeBuffer>[];

      for (var field in ctx.fields) {
        // Skip excluded fields
        if (ctx.excluded[field.name]?.canSerialize == false) continue;

        var alias = ctx.resolveFieldName(field.name);
        var typeScriptType = await compileToTypeScriptType(
            field.name, field.type, ext, buildStep);

        // foo: string;
        buf.writeln('$alias: $typeScriptType;');
      }

      buf
        ..outdent()
        ..writeln('}');

      for (var b in ext) {
        b.copyInto(buf);
      }
    }

    //buf
    //  ..outdent()
    //  ..writeln('}');

    buildStep.writeAsString(
      buildStep.inputId.changeExtension('.d.ts'),
      buf.toString(),
    );
  }
}
