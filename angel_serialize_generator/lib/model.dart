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
      generateEqualsOperator(ctx, clazz, file);

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

      for (var param in ctx.constructorParameters) {
        constructor.requiredParameters.add(new Parameter((b) => b
          ..name = param.name
          ..type = convertTypeReference(param.type)));
      }

      for (var field in ctx.fields) {
        if (isListOrMapType(field.type)) {
          String typeName = const TypeChecker.fromRuntime(List)
                  .isAssignableFromType(field.type)
              ? 'List'
              : 'Map';
          var defaultValue = typeName == 'List' ? '[]' : '{}';
          constructor.initializers.add(new Code('''
              this.${field.name} =
                new $typeName.unmodifiable(${field.name} ?? $defaultValue)'''));
        }
      }

      if (ctx.constructorParameters.isNotEmpty) {
        constructor.initializers.add(
            new Code('super(${ctx.constructorParameters.map((p) => p.name).join(
                ',')})'));
      }

      for (var field in ctx.fields) {
        constructor.optionalParameters.add(new Parameter((b) {
          b
            ..name = field.name
            ..named = true;

          if (!isListOrMapType(field.type))
            b.toThis = true;
          else {
            b.type = convertTypeReference(field.type);
          }

          if (ctx.requiredFields.containsKey(field.name)) {
            b.annotations.add(new CodeExpression(new Code('required')));
          }
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

  static String generateEquality(DartType type, [bool nullable = false]) {
    //if (type is! InterfaceType) return 'const DefaultEquality()';
    var it = type as InterfaceType;
    if (const TypeChecker.fromRuntime(List).isAssignableFromType(type)) {
      if (it.typeParameters.length == 1) {
        var eq = generateEquality(it.typeArguments[0]);
        return 'const ListEquality<${it.typeArguments[0].name}>($eq)';
      } else
        return 'const ListEquality<${it.typeArguments[0].name}>()';
    } else if (const TypeChecker.fromRuntime(Map).isAssignableFromType(type)) {
      if (it.typeParameters.length == 2) {
        var keq = generateEquality(it.typeArguments[0]),
            veq = generateEquality(it.typeArguments[1]);
        return 'const MapEquality<${it.typeArguments[0].name}, ${it
            .typeArguments[1].name}>(keys: $keq, values: $veq)';
      } else
        return 'const MapEquality()<${it.typeArguments[0].name}, ${it
            .typeArguments[1].name}>';
    }

    return nullable ? null : 'const DefaultEquality<${type.name}>()';
  }

  static String Function(String, String) generateComparator(DartType type) {
    if (type is! InterfaceType) return (a, b) => '$a == $b';
    var eq = generateEquality(type, true);
    if (eq == null) return (a, b) => '$a == $b';
    return (a, b) => '$eq.equals($a, $b)';
  }

  void generateEqualsOperator(
      BuildContext ctx, ClassBuilder clazz, LibraryBuilder file) {
    clazz.methods.add(new Method((method) {
      method
        ..name = 'operator =='
        ..returns = new Reference('bool')
        ..requiredParameters.add(new Parameter((b) => b.name = 'other'));

      var buf = ['other is ${ctx.originalClassName}'];

      buf.addAll(ctx.fields.map((f) {
        return generateComparator(f.type)('other.${f.name}', f.name);
      }));

      method.body = new Code('return ${buf.join('&&')};');
    }));
  }
}
