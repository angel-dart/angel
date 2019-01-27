part of angel_serialize_generator;

class SerializerGenerator extends GeneratorForAnnotation<Serializable> {
  final bool autoSnakeCaseNames;

  const SerializerGenerator({this.autoSnakeCaseNames: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element.kind != ElementKind.CLASS)
      throw 'Only classes can be annotated with a @Serializable() annotation.';

    var ctx = await buildContext(element as ClassElement, annotation, buildStep,
        await buildStep.resolver, autoSnakeCaseNames != false);

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
            ..type = refer(ctx.originalClassName);
        }));

      var buf = new StringBuffer();

      ctx.requiredFields.forEach((key, msg) {
        if (ctx.excluded[key]?.canSerialize == false) return;
        buf.writeln('''
        if (model.$key == null) {
          throw new FormatException("$msg");
        }
        ''');
      });

      buf.writeln('return {');
      int i = 0;

      // Add named parameters
      for (var field in ctx.fields) {
        var type = ctx.resolveSerializedFieldType(field.name);

        // Skip excluded fields
        if (ctx.excluded[field.name]?.canSerialize == false) continue;

        var alias = ctx.resolveFieldName(field.name);

        if (i++ > 0) buf.write(', ');

        String serializedRepresentation = 'model.${field.name}';

        String serializerToMap(ReCase rc, String value) {
          // if (rc.pascalCase == ctx.modelClassName) {
          //   return '($value)?.toJson()';
          // }
          return '${rc.pascalCase}Serializer.toMap($value)';
        }

        if (ctx.fieldInfo[field.name]?.serializer != null) {
          var name = MirrorSystem.getName(ctx.fieldInfo[field.name].serializer);
          serializedRepresentation = '$name(model.${field.name})';
        }

        // Serialize dates
        else if (dateTimeTypeChecker.isAssignableFromType(type))
          serializedRepresentation = 'model.${field.name}?.toIso8601String()';

        // Serialize model classes via `XSerializer.toMap`
        else if (isModelClass(type)) {
          var rc = new ReCase(type.name);
          serializedRepresentation =
              '${serializerToMap(rc, 'model.${field.name}')}';
        } else if (type is InterfaceType) {
          if (isListOfModelType(type)) {
            var name = type.typeArguments[0].name;
            if (name.startsWith('_')) name = name.substring(1);
            var rc = new ReCase(name);
            var m = serializerToMap(rc, 'm');
            serializedRepresentation = '''
            model.${field.name}
              ?.map((m) => $m)
              ?.toList()''';
          } else if (isMapToModelType(type)) {
            var rc = new ReCase(type.typeArguments[1].name);
            serializedRepresentation =
                '''model.${field.name}.keys?.fold({}, (map, key) {
              return map..[key] =
              ${serializerToMap(rc, 'model.${field.name}[key]')};
            })''';
          } else if (type.element.isEnum) {
            serializedRepresentation = '''
            model.${field.name} == null ?
              null
              : ${type.name}.values.indexOf(model.${field.name})
            ''';
          } else if (const TypeChecker.fromRuntime(Uint8List)
              .isAssignableFromType(type)) {
            serializedRepresentation = '''
            model.${field.name} == null ?
              null
              : base64.encode(model.${field.name})
            ''';
          }
        }

        buf.write("'$alias': $serializedRepresentation");
      }

      buf.write('};');
      method.body = new Block.of([
        new Code('if (model == null) { return null; }'),
        new Code(buf.toString()),
      ]);
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

      // Add all `super` params
      if (ctx.constructorParameters.isNotEmpty) {
        for (var param in ctx.constructorParameters) {
          method.requiredParameters.add(new Parameter((b) => b
            ..name = param.name
            ..type = convertTypeReference(param.type)));
        }
      }

      var buf = new StringBuffer();

      ctx.requiredFields.forEach((key, msg) {
        if (ctx.excluded[key]?.canDeserialize == false) return;
        var name = ctx.resolveFieldName(key);
        buf.writeln('''
        if (map['$name'] == null) {
          throw new FormatException("$msg");
        }
        ''');
      });

      buf.writeln('return new ${ctx.modelClassName}(');
      int i = 0;

      for (var param in ctx.constructorParameters) {
        if (i++ > 0) buf.write(', ');
        buf.write(param.name);
      }

      for (var field in ctx.fields) {
        var type = ctx.resolveSerializedFieldType(field.name);

        if (ctx.excluded[field.name]?.canDeserialize == false) continue;

        var alias = ctx.resolveFieldName(field.name);

        if (i++ > 0) buf.write(', ');

        String deserializedRepresentation =
            "map['$alias'] as ${typeToString(type)}";

        var defaultValue = 'null';
        var existingDefault = ctx.defaults[field.name];

        if (existingDefault != null) {
          defaultValue = dartObjectToString(existingDefault);
          deserializedRepresentation =
              '$deserializedRepresentation ?? $defaultValue';
        }

        if (ctx.fieldInfo[field.name]?.deserializer != null) {
          var name =
              MirrorSystem.getName(ctx.fieldInfo[field.name].deserializer);
          deserializedRepresentation = "$name(map['$alias'])";
        } else if (dateTimeTypeChecker.isAssignableFromType(type))
          deserializedRepresentation = "map['$alias'] != null ? "
              "(map['$alias'] is DateTime ? (map['$alias'] as DateTime) : DateTime.parse(map['$alias'].toString()))"
              " : $defaultValue";

        // Serialize model classes via `XSerializer.toMap`
        else if (isModelClass(type)) {
          var rc = new ReCase(type.name);
          deserializedRepresentation = "map['$alias'] != null"
              " ? ${rc.pascalCase}Serializer.fromMap(map['$alias'] as Map)"
              " : $defaultValue";
        } else if (type is InterfaceType) {
          if (isListOfModelType(type)) {
            var rc = new ReCase(type.typeArguments[0].name);
            deserializedRepresentation = "map['$alias'] is Iterable"
                " ? new List.unmodifiable(((map['$alias'] as Iterable)"
                ".where((x) => x is Map))"
                ".cast<Map>()"
                ".map(${rc.pascalCase}Serializer.fromMap))"
                " : $defaultValue";
          } else if (isMapToModelType(type)) {
            var rc = new ReCase(type.typeArguments[1].name);
            deserializedRepresentation = '''
                map['$alias'] is Map
                  ? new Map.unmodifiable((map['$alias'] as Map).keys.fold({}, (out, key) {
                       return out..[key] = ${rc.pascalCase}Serializer
                        .fromMap(((map['$alias'] as Map)[key]) as Map);
                    }))
                  : $defaultValue
            ''';
          } else if (type.element.isEnum) {
            deserializedRepresentation = '''
            map['$alias'] is ${type.name}
              ? (map['$alias'] as ${type.name})
              :
              (
                map['$alias'] is int
                ? ${type.name}.values[map['$alias'] as int]
                : $defaultValue
              )
            ''';
          } else if (const TypeChecker.fromRuntime(List)
                  .isAssignableFromType(type) &&
              type.typeArguments.length == 1) {
            var arg = convertTypeReference(type.typeArguments[0])
                .accept(new DartEmitter());
            deserializedRepresentation = '''
                map['$alias'] is Iterable
                  ? (map['$alias'] as Iterable).cast<$arg>().toList()
                  : $defaultValue
                ''';
          } else if (const TypeChecker.fromRuntime(Map)
                  .isAssignableFromType(type) &&
              type.typeArguments.length == 2) {
            var key = convertTypeReference(type.typeArguments[0])
                .accept(new DartEmitter());
            var value = convertTypeReference(type.typeArguments[1])
                .accept(new DartEmitter());
            deserializedRepresentation = '''
                map['$alias'] is Map
                  ? (map['$alias'] as Map).cast<$key, $value>()
                  : $defaultValue
                ''';
          } else if (const TypeChecker.fromRuntime(Uint8List)
              .isAssignableFromType(type)) {
            deserializedRepresentation = '''
            map['$alias'] is Uint8List
              ? (map['$alias'] as Uint8List)
              :
              (
                map['$alias'] is Iterable<int>
                  ? new Uint8List.fromList((map['$alias'] as Iterable<int>).toList())
                  :
                  (
                    map['$alias'] is String
                      ? new Uint8List.fromList(base64.decode(map['$alias'] as String))
                      : $defaultValue
                  )
              )
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

      clazz.fields.add(new Field((b) {
        b
          ..static = true
          ..modifier = FieldModifier.constant
          ..type = new TypeReference((b) => b
            ..symbol = 'List'
            ..types.add(refer('String')))
          ..name = 'allFields'
          ..assignment = literalConstList(
                  ctx.fields.map((f) => refer(f.name)).toList(),
                  refer('String'))
              .code;
      }));

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
