part of angel_serialize_generator;

class SerializerGenerator extends GeneratorForAnnotation<Serializable> {
  final bool autoSnakeCaseNames;

  const SerializerGenerator({this.autoSnakeCaseNames: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element.kind != ElementKind.CLASS)
      throw 'Only classes can be annotated with a @Serializable() annotation.';

    var ctx = await buildContext(element, annotation, buildStep,
        await buildStep.resolver, true, autoSnakeCaseNames != false);

    var serializers = annotation.peek('serializers')?.listValue ?? [];

    if (serializers.isEmpty) return null;

    // Check if any serializer is recognized
    if (!serializers.any((s) => Serializers.all.contains(s.toIntValue()))) {
      return null;
    }

    var lib = new Library((b) {
      generateClass(serializers.map((s) => s.toIntValue()).toList(), ctx, b);
      generateFieldsClass(ctx, b);
    });

    var buf = lib.accept(new DartEmitter());
    return buf.toString();
  }

  /// Generate a serializer class.
  void generateClass(
      List<int> serializers, BuildContext ctx, LibraryBuilder file) {
    file.body.add(new Class((clazz) {
      clazz
        ..name = '${ctx.modelClassNameRecase.pascalCase}Serializer'
        ..abstract = true;

      if (serializers.contains(Serializers.map)) {
        generateFromMapMethod(clazz, ctx, file);
      }

      if (serializers.contains(Serializers.map) ||
          serializers.contains(Serializers.json)) {
        generateToMapMethod(clazz, ctx, file);
      }
    }));
  }

  void generateToMapMethod(
      ClassBuilder clazz, BuildContext ctx, LibraryBuilder file) {
    clazz.methods.add(new Method((method) {
      method
        ..static = true
        ..name = 'toMap'
        ..returns = new Reference('Map<String, dynamic>')
        ..requiredParameters.add(new Parameter((b) {
          b
            ..name = 'model'
            ..type = ctx.modelClassType;
        }));

      var buf = new StringBuffer('return {');
      int i = 0;

      // Add named parameters
      for (var field in ctx.fields) {
        // Skip excluded fields
        if (ctx.excluded[field.name]?.canSerialize == false) continue;

        var alias = ctx.resolveFieldName(field.name);

        if (i++ > 0) buf.write(', ');

        String serializedRepresentation = 'model.${field.name}';

        // Serialize dates
        if (dateTimeTypeChecker.isAssignableFromType(field.type))
          serializedRepresentation = 'model.${field.name}?.toIso8601String()';

        // Serialize model classes via `XSerializer.toMap`
        else if (isModelClass(field.type)) {
          var rc = new ReCase(field.type.name);
          serializedRepresentation =
              '${rc.pascalCase}Serializer.toMap(model.${field.name})';
        } else if (field.type is InterfaceType) {
          var t = field.type as InterfaceType;

          if (isListModelType(t)) {
            var rc = new ReCase(t.typeArguments[0].name);
            serializedRepresentation = 'model.${field.name}?.map(${rc
                .pascalCase}Serializer.toMap)?.toList()';
          } else if (isMapToModelType(t)) {
            var rc = new ReCase(t.typeArguments[1].name);
            serializedRepresentation =
                '''model.${field.name}.keys?.fold({}, (map, key) {
              return map..[key] = ${rc.pascalCase}Serializer.toMap(model.${field
                .name}[key]);
            })''';
          }
        }

        buf.write("'$alias': $serializedRepresentation");
      }

      buf.write('};');
      method.body = new Code(buf.toString());
    }));
  }

  void generateFromMapMethod(
      ClassBuilder clazz, BuildContext ctx, LibraryBuilder file) {
    clazz.methods.add(new Method((method) {
      method
        ..static = true
        ..name = 'fromMap'
        ..returns = ctx.modelClassType
        ..requiredParameters.add(
          new Parameter((b) => b
            ..name = 'map'
            ..type = new Reference('Map')),
        );

      var buf = new StringBuffer('return new ${ctx.modelClassName}(');
      int i = 0;

      for (var field in ctx.fields) {
        if (ctx.excluded[field.name]?.canDeserialize == false) continue;

        var alias = ctx.resolveFieldName(field.name);

        if (i++ > 0) buf.write(', ');

        String deserializedRepresentation = "map['$alias']";

        // Deserialize dates
        if (dateTimeTypeChecker.isAssignableFromType(field.type))
          deserializedRepresentation = "map['$alias'] != null ? "
              "(map['$alias'] is DateTime ? map['$alias'] : DateTime.parse(map['$alias']))"
              " : null";

        // Serialize model classes via `XSerializer.toMap`
        else if (isModelClass(field.type)) {
          var rc = new ReCase(field.type.name);
          deserializedRepresentation = "map['$alias'] != null"
              " ? ${rc.pascalCase}Serializer.fromMap(map['$alias'])"
              " : null";
        } else if (field.type is InterfaceType) {
          var t = field.type as InterfaceType;

          if (isListModelType(t)) {
            var rc = new ReCase(t.typeArguments[0].name);
            deserializedRepresentation = "map['$alias'] is Iterable"
                " ? map['$alias'].map(${rc
                .pascalCase}Serializer.fromMap).toList()"
                " : null";
          } else if (isMapToModelType(t)) {
            var rc = new ReCase(t.typeArguments[1].name);
            deserializedRepresentation = '''
                map['$alias'] is Map
                  ? map['$alias'].keys.fold({}, (out, key) {
                       return out..[key] = ${rc
                .pascalCase}Serializer.fromMap(map['$alias'][key]);
                    })
                  : null
            ''';
          }
        }

        buf.write('${field.name}: $deserializedRepresentation');
      }

      buf.write(');');
      method.body = new Code(buf.toString());
    }));
  }

  void generateFieldsClass(BuildContext ctx, LibraryBuilder file) {
    file.body.add(new Class((clazz) {
      clazz
        ..abstract = true
        ..name = '${ctx.modelClassNameRecase.pascalCase}Fields';

      for (var field in ctx.fields) {
        clazz.fields.add(new Field((b) {
          b
            ..static = true
            ..modifier = FieldModifier.constant
            ..type = new Reference('String')
            ..name = field.name
            ..assignment = new Code("'${ctx.resolveFieldName(field.name)}'");
        }));
      }
    }));
  }
}
