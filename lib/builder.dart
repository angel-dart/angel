import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/src/annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'angel_serialize.dart';

class JsonModelGenerator extends GeneratorForAnnotation<Serializable> {
  const JsonModelGenerator();

  @override
  Future<String> generateForAnnotatedElement(
      Element element, Serializable annotation, BuildStep buildStep) async {
    if (element.kind != ElementKind.CLASS)
      throw 'Only classes can be annotated with a @Serializable() annotation.';
    var lib = generateSerializerLibrary(element);
    return prettyToSource(lib.buildAst());
  }

  LibraryBuilder generateSerializerLibrary(ClassElement clazz) {
    var lib = new LibraryBuilder();
    lib.addMember(generateBaseModelClass(clazz));
    return lib;
  }

  ClassBuilder generateBaseModelClass(ClassElement clazz) {
    if (!clazz.name.startsWith('_'))
      throw 'Classes annotated with @Serializable() must have names starting with a leading underscore.';

    var genClassName = clazz.name.substring(1);
    var genClass =
        new ClassBuilder(genClassName, asExtends: new TypeBuilder(clazz.name));
    Map<String, DartType> fields = {};
    Map<String, String> aliases = {};

    // Find all fields
    for (var field in clazz.fields) {
      // Skip if annotated with @exclude
      var excludeAnnotation = field.metadata.firstWhere(
          (ann) => matchAnnotation(Exclude, ann),
          orElse: () => null);

      if (excludeAnnotation == null) {
        // Register the field
        fields[field.name] = field.type;

        // Search for Alias
        var aliasAnnotation = field.metadata.firstWhere(
            (ann) => matchAnnotation(Alias, ann),
            orElse: () => null);
        if (aliasAnnotation != null) {
          var alias = instantiateAnnotation(aliasAnnotation) as Alias;
          aliases[field.name] = alias.name;
        }
      }
    }

    // Now, add all fields to the base class
    clazz.fields.forEach((field) {
      genClass.addField(
          varField(field.name, type: new TypeBuilder(field.type.displayName))
            ..addAnnotation(reference('override')));
    });

    // Create convenience constructor
    var convenienceConstructor = constructor(clazz.fields.map((field) {
      return thisField(named(parameter(field.name)));
    }));
    genClass.addConstructor(convenienceConstructor);

    // Create toJson
    Map<String, ExpressionBuilder> toJsonFields = {};

    fields.forEach((fieldName, type) {
      var resolvedName =
          aliases.containsKey(fieldName) ? aliases[fieldName] : fieldName;
      ExpressionBuilder value;

      // DateTime
      if (type.name == 'DateTime') {
        value = reference(fieldName).equals(literal(null)).ternary(
            literal(null), reference(fieldName).invoke('toIso8601String', []));
      }

      // Anything else
      else {
        value = reference(fieldName);
      }

      toJsonFields[resolvedName] = value;
    });

    var toJson = new MethodBuilder('toJson',
        returnType: new TypeBuilder('Map', genericTypes: [
          new TypeBuilder('String'),
          new TypeBuilder('dynamic')
        ]),
        returns: map(toJsonFields));
    genClass.addMethod(toJson);

    // Create factory [name].fromJson
    var fromJson = new ConstructorBuilder(name: 'fromJson', asFactory: true);
    fromJson.addPositional(parameter('data', [new TypeBuilder('Map')]));
    var namedParams =
        fields.keys.fold<Map<String, ExpressionBuilder>>({}, (out, fieldName) {
      var resolvedName =
          aliases.containsKey(fieldName) ? aliases[fieldName] : fieldName;
      var mapKey = reference('data')[literal(resolvedName)];
      ExpressionBuilder value = mapKey;
      var type = fields[fieldName];

      // DateTime
      if (type.name == 'DateTime') {
        // map['foo'] is DateTime ? map['foo'] : (map['foo'] is String ? DateTime.parse(map['foo']) : null)
        var dt = new TypeBuilder('DateTime');
        value = mapKey.isInstanceOf(dt).ternary(
            mapKey,
            (mapKey.isInstanceOf(new TypeBuilder('String')).ternary(
                    new TypeBuilder('DateTime').invoke('parse', [mapKey]),
                    literal(null)))
                .parentheses());
      }

      bool done = false;

      // Handle List
      if (type.toString().contains('List') && type is ParameterizedType) {
        var listType = type.typeArguments.first;
        if (listType.element is ClassElement) {
          var genericClass = listType.element as ClassElement;
          String fromJsonClassName;
          bool hasFromJson =
              genericClass.constructors.any((c) => c.name == 'fromJson');

          if (hasFromJson) {
            fromJsonClassName = genericClass.displayName;
          } else {
            // If it has a serializable annotation, act accordingly.
            if (genericClass.metadata
                .any((ann) => matchAnnotation(Serializable, ann))) {
              fromJsonClassName = genericClass.displayName.substring(1);
              hasFromJson = true;
            }
          }

          // Check for fromJson
          if (hasFromJson) {
            var outputType = new TypeBuilder(fromJsonClassName);
            var x = reference('x');
            value = mapKey.isInstanceOf(lib$core.List).ternary(
                mapKey.invoke('map', [
                  new MethodBuilder.closure(
                      returns: x.equals(literal(null)).ternary(
                          literal(null),
                          (x.isInstanceOf(outputType).ternary(
                                  x,
                                  outputType.newInstance([reference('x')],
                                      constructor: 'fromJson')))
                              .parentheses()))
                    ..addPositional(parameter('x'))
                ]).invoke('toList', []),
                literal(null));
            done = true;
          }
        }
      }

      // Check for fromJson
      if (!done && type.element is ClassElement) {
        String fromJsonClassName;
        var genericClass = type.element as ClassElement;
        bool hasFromJson =
            genericClass.constructors.any((c) => c.name == 'fromJson');

        if (hasFromJson) {
          fromJsonClassName = type.displayName;
        } else {
          // If it has a serializable annotation, act accordingly.
          if (genericClass.metadata
              .any((ann) => matchAnnotation(Serializable, ann))) {
            fromJsonClassName = type.displayName.substring(1);
            hasFromJson = true;
          }
        }

        // Check for fromJson
        if (hasFromJson) {
          var outputType = new TypeBuilder(fromJsonClassName);
          value = mapKey.equals(literal(null)).ternary(
              literal(null),
              (mapKey.isInstanceOf(outputType).ternary(
                      mapKey,
                      outputType
                          .newInstance([mapKey], constructor: 'fromJson')))
                  .parentheses());
        }
      }

      // Handle Map...
      if (!done &&
          type.toString().contains('Map') &&
          type is ParameterizedType &&
          type.typeArguments.length >= 2) {
        var targetType = type.typeArguments[1];
        if (targetType.element is ClassElement) {
          String fromJsonClassName;
          var genericClass = targetType.element as ClassElement;
          bool hasFromJson =
              genericClass.constructors.any((c) => c.name == 'fromJson');

          if (hasFromJson) {
            fromJsonClassName = targetType.displayName;
          } else {
            // If it has a serializable annotation, act accordingly.
            if (genericClass.metadata
                .any((ann) => matchAnnotation(Serializable, ann))) {
              fromJsonClassName = targetType.displayName.substring(1);
              hasFromJson = true;
            }
          }

          // Check for fromJson
          if (hasFromJson) {
            var outputType = new TypeBuilder(fromJsonClassName);
            var v = mapKey[reference('k')];
            value = mapKey.isInstanceOf(lib$core.Map).ternary(
                mapKey.property('keys').invoke('fold', [
                  map({}),
                  new MethodBuilder.closure()
                    ..addStatements([
                      v
                          .equals(literal(null))
                          .ternary(
                              literal(null),
                              (v.isInstanceOf(outputType).ternary(
                                      v,
                                      outputType.newInstance([v],
                                          constructor: 'fromJson')))
                                  .parentheses())
                          .asAssign(reference('out')[reference('k')]),
                      reference('out').asReturn()
                    ])
                    ..addPositional(parameter('out'))
                    ..addPositional(parameter('k'))
                ]),
                literal(null));
          } else {
            value = mapKey
                .isInstanceOf(lib$core.Map)
                .ternary(mapKey, literal(null));
          }
        }
      }

      return out..[fieldName] = value;
    });
    fromJson.addStatement(new TypeBuilder(genClassName)
        .newInstance([], named: namedParams).asReturn());
    genClass.addConstructor(fromJson);

    // Create `parse` to just forward
    var parseMethod = new MethodBuilder('parse',
        returnType: new TypeBuilder(genClassName),
        returns: new TypeBuilder(genClassName)
            .newInstance([reference('map')], constructor: 'fromJson'));
    parseMethod.addPositional(parameter('map', [new TypeBuilder('Map')]));
    genClass.addMethod(parseMethod, asStatic: true);

    return genClass;
  }
}
