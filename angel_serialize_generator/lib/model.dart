part of angel_serialize_generator;

class JsonModelGenerator extends GeneratorForAnnotation<Serializable> {
  final bool autoIdAndDateFields;

  const JsonModelGenerator({this.autoIdAndDateFields: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element.kind != ElementKind.CLASS)
      throw 'Only classes can be annotated with a @Serializable() annotation.';

    var ctx = await buildContext(element, annotation, buildStep,
        await buildStep.resolver, true, autoIdAndDateFields != false);

    var lib = new Library((b) {
      generateClass(ctx, b, annotation);
    });

    var buf = lib.accept(new DartEmitter());
    return buf.toString();
  }

  /// Generate an extended model class.
  void generateClass(
      BuildContext ctx, LibraryBuilder file, ConstantReader annotation) {
    file.body.add(new Class((clazz) {
      clazz
        ..name = ctx.modelClassNameRecase.pascalCase
        ..extend = new Reference(ctx.originalClassName);

      for (var field in ctx.fields) {
        clazz.fields.add(new Field((b) {
          b
            ..name = field.name
            ..modifier = FieldModifier.final$
            ..annotations.add(new CodeExpression(new Code('override')))
            ..type = convertTypeReference(field.type);
        }));
      }

      generateConstructor(ctx, clazz, file);
      generateCopyWithMethod(ctx, clazz, file);

      // Generate toJson() method if necessary
      var serializers = annotation.peek('serializers')?.listValue ?? [];

      if (serializers.any((o) => o.toIntValue() == Serializers.json)) {
        clazz.methods.add(new Method((method) {
          method
            ..name = 'toJson'
            ..returns = new Reference('Map<String, dynamic>')
            ..body = new Code('return ${clazz.name}Serializer.toMap(this);');
        }));
      }
    }));
  }

  /// Generate a constructor with named parameters.
  void generateConstructor(
      BuildContext ctx, ClassBuilder clazz, LibraryBuilder file) {
    clazz.constructors.add(new Constructor((constructor) {
      // Add all `super` params
      if (ctx.constructorParameters.isNotEmpty) {
        for (var param in ctx.constructorParameters) {
          constructor.requiredParameters.add(new Parameter((b) => b
            ..name = param.name
            ..type = convertTypeReference(param.type)));
        }

        constructor.initializers.add(new Code(
            'super(${ctx.constructorParameters.map((p) => p.name).join(',')})'));
      }

      for (var field in ctx.fields) {
        constructor.optionalParameters.add(new Parameter((b) {
          b
            ..name = field.name
            ..named = true
            ..toThis = true;
        }));
      }
    }));
  }

  /// Generate a `copyWith` method.
  void generateCopyWithMethod(
      BuildContext ctx, ClassBuilder clazz, LibraryBuilder file) {
    clazz.methods.add(new Method((method) {
      method
        ..name = 'copyWith'
        ..returns = ctx.modelClassType;
        
      // Add all `super` params
      if (ctx.constructorParameters.isNotEmpty) {
        for (var param in ctx.constructorParameters) {
          method.requiredParameters.add(new Parameter((b) => b
            ..name = param.name
            ..type = convertTypeReference(param.type)));
        }
      }

      var buf = new StringBuffer('return new ${ctx.modelClassName}(');
      int i = 0;

      for (var param in ctx.constructorParameters) {
        if (i++ > 0) buf.write(', ');
        buf.write(param.name);
      }

      // Add named parameters
      for (var field in ctx.fields) {
        method.optionalParameters.add(new Parameter((b) {
          b
            ..name = field.name
            ..named = true
            ..type = convertTypeReference(field.type);
        }));

        if (i++ > 0) buf.write(', ');
        buf.write('${field.name}: ${field.name} ?? this.${field.name}');
      }

      buf.write(');');
      method.body = new Code(buf.toString());
    }));
  }
}
