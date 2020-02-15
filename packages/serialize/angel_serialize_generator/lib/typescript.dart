part of angel_serialize_generator;

class TypeScriptDefinitionBuilder implements Builder {
  final bool autoSnakeCaseNames;

  const TypeScriptDefinitionBuilder({this.autoSnakeCaseNames = true});

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      '.dart': ['.d.ts']
    };
  }

  Future<String> compileToTypeScriptType(
      BuildContext ctx,
      String fieldName,
      DartType type,
      List<String> refs,
      List<CodeBuffer> ext,
      BuildStep buildStep) async {
    String typeScriptType = 'any';

    var types = const {
      num: 'number',
      bool: 'boolean',
      String: 'string',
      Symbol: 'Symbol',
    };

    types.forEach((t, tsType) {
      if (TypeChecker.fromRuntime(t).isAssignableFromType(type)) {
        typeScriptType = tsType;
      }
    });

    if (type is InterfaceType) {
      if (isListOfModelType(type)) {
        var arg = await compileToTypeScriptType(
            ctx, fieldName, type.typeArguments[0], refs, ext, buildStep);
        typeScriptType = '$arg[]';
      } else if (const TypeChecker.fromRuntime(Map)
              .isAssignableFromType(type) &&
          type.typeArguments.length == 2) {
        var key = await compileToTypeScriptType(
            ctx, fieldName, type.typeArguments[0], refs, ext, buildStep);
        var value = await compileToTypeScriptType(
            ctx, fieldName, type.typeArguments[1], refs, ext, buildStep);
        //var modelType = type.typeArguments[1];
        /*var innerCtx = await buildContext(
        modelType.element,
        ConstantReader(
            serializableTypeChecker.firstAnnotationOf(modelType.element)),
        buildStep,
        buildStep.resolver,
        autoSnakeCaseNames,
        true,
      );*/

        typeScriptType =
            ctx.modelClassNameRecase.pascalCase + ReCase(fieldName).pascalCase;

        ext.add(CodeBuffer()
          ..writeln('interface $typeScriptType {')
          ..indent()
          ..writeln('[key: $key]: $value;')
          ..outdent()
          ..writeln('}'));
      } else if (const TypeChecker.fromRuntime(List)
          .isAssignableFromType(type)) {
        if (type.typeArguments.isEmpty) {
          typeScriptType = 'any[]';
        } else {
          var arg = await compileToTypeScriptType(
              ctx, fieldName, type.typeArguments[0], refs, ext, buildStep);
          typeScriptType = '$arg[]';
        }
      } else if (isModelClass(type)) {
        var sourcePath = buildStep.inputId.uri.toString();
        var targetPath = type.element.source.uri.toString();

        if (!p.equals(sourcePath, targetPath)) {
          var relative = p.relative(targetPath, from: sourcePath);
          String ref;

          if (type.element.source.uri.scheme == 'asset') {
            var id = AssetId.resolve(type.element.source.uri.toString());
            if (id.package != buildStep.inputId.package) {
              ref = '/// <reference types="${id.package}" />';
            }
          }

          if (ref == null) {
            // var relative = (p.dirname(targetPath) == p.dirname(sourcePath))
            //     ? p.basename(targetPath)
            //     : p.relative(targetPath, from: sourcePath);
            var parent = p.dirname(relative);
            var filename =
                p.setExtension(p.basenameWithoutExtension(relative), '.d.ts');
            relative = p.joinAll(p.split(parent).toList()..add(filename));
            ref = '/// <reference path="$relative" />';
          }
          if (!refs.contains(ref)) refs.add(ref);
        }

        var ctx = await buildContext(
          type.element,
          ConstantReader(
              serializableTypeChecker.firstAnnotationOf(type.element)),
          buildStep,
          buildStep.resolver,
          autoSnakeCaseNames,
        );
        typeScriptType = ctx.modelClassNameRecase.pascalCase;
      }
    }

    return typeScriptType;
  }

  @override
  Future build(BuildStep buildStep) async {
    var contexts = <BuildContext>[];
    LibraryReader lib;

    try {
      lib = LibraryReader(await buildStep.inputLibrary);
    } catch (_) {
      return;
    }

    var elements = <AnnotatedElement>[];

    try {
      elements = lib
          .annotatedWith(const TypeChecker.fromRuntime(Serializable))
          .toList();
    } catch (_) {
      // Ignore error in source_gen/build_runner that has no explanation
    }

    for (var element in elements) {
      if (element.element.kind != ElementKind.CLASS) {
        throw 'Only classes can be annotated with a @Serializable() annotation.';
      }

      var annotation = element.annotation;

      var serializers = annotation.peek('serializers')?.listValue ?? [];

      if (serializers.isEmpty) continue;

      // Check if TypeScript serializer is supported
      if (!serializers.any((s) => s.toIntValue() == Serializers.typescript)) {
        continue;
      }

      contexts.add(await buildContext(
          element.element as ClassElement,
          element.annotation,
          buildStep,
          await buildStep.resolver,
          autoSnakeCaseNames != false));
    }

    if (contexts.isEmpty) return;

    var refs = <String>[];
    var buf = CodeBuffer(
      trailingNewline: true,
      sourceUrl: buildStep.inputId.uri,
    );

    buf.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');

    // declare module `foo` {
    buf
      ..writeln("declare module '${buildStep.inputId.package}' {")
      ..indent();

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
        var typeScriptType = await compileToTypeScriptType(ctx, field.name,
            ctx.resolveSerializedFieldType(field.name), refs, ext, buildStep);

        // foo: string;
        if (!ctx.requiredFields.containsKey(field.name)) alias += '?';
        buf.writeln('$alias: $typeScriptType;');
      }

      buf
        ..outdent()
        ..writeln('}');

      for (var b in ext) {
        b.copyInto(buf);
      }
    }

    buf
      ..outdent()
      ..writeln('}');
    var finalBuf = CodeBuffer();
    refs.forEach(finalBuf.writeln);
    buf.copyInto(finalBuf);

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.d.ts'),
      finalBuf.toString(),
    );
  }
}
