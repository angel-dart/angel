import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'context.dart';

const TypeChecker aliasTypeChecker = const TypeChecker.fromRuntime(Alias);

const TypeChecker dateTimeTypeChecker = const TypeChecker.fromRuntime(DateTime);

const TypeChecker excludeTypeChecker = const TypeChecker.fromRuntime(Exclude);

const TypeChecker serializableTypeChecker =
    const TypeChecker.fromRuntime(Serializable);

/// Create a [BuildContext].
Future<BuildContext> buildContext(
    ClassElement clazz,
    ConstantReader annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
    bool autoIdAndDateFields,
    {bool heedExclude: true}) async {
  // Check for autoIdAndDateFields, autoSnakeCaseNames
  autoIdAndDateFields =
      annotation.peek('autoIdAndDateFields')?.boolValue ?? autoIdAndDateFields;
  autoSnakeCaseNames =
      annotation.peek('autoSnakeCaseNames')?.boolValue ?? autoSnakeCaseNames;

  var ctx = new BuildContext(annotation, clazz,
      originalClassName: clazz.name,
      sourceFilename: p.basename(buildStep.inputId.path),
      autoIdAndDateFields: autoIdAndDateFields,
      autoSnakeCaseNames: autoSnakeCaseNames);
  var lib = await resolver.libraryFor(buildStep.inputId);
  List<String> fieldNames = [];

  for (var field in clazz.fields) {
    if (field.getter != null &&
        (field.setter != null || field.getter.isAbstract)) {
      var el = field.setter == null ? field.getter : field;
      fieldNames.add(field.name);
      // Skip if annotated with @exclude
      var excludeAnnotation = excludeTypeChecker.firstAnnotationOf(el);

      if (excludeAnnotation != null) {
        var cr = new ConstantReader(excludeAnnotation);

        ctx.excluded[field.name] = new Exclude(
          canSerialize: cr.read('canSerialize').boolValue,
          canDeserialize: cr.read('canDeserialize').boolValue,
        );
      }

      // Check for alias
      Alias alias;
      var aliasAnn = aliasTypeChecker.firstAnnotationOf(el);

      if (aliasAnn != null) {
        alias = new Alias(aliasAnn.getField('name').toStringValue());
      }

      if (alias?.name?.isNotEmpty == true) {
        ctx.aliases[field.name] = alias.name;
      } else if (autoSnakeCaseNames != false) {
        ctx.aliases[field.name] = new ReCase(field.name).snakeCase;
      }

      // Check for @required
      var required =
          const TypeChecker.fromRuntime(Required).firstAnnotationOf(el);

      if (required != null) {
        var cr = new ConstantReader(required);
        var reason = cr.peek('reason')?.stringValue ??
            "Missing field '${ctx.resolveFieldName(field.name)}' on ${ctx
                .modelClassName}.";
        ctx.requiredFields[field.name] = reason;
      }

      ctx.fields.add(field);
    }
  }

  if (autoIdAndDateFields != false) {
    if (!fieldNames.contains('id')) {
      var idField =
          new ShimFieldImpl('id', lib.context.typeProvider.stringType);
      ctx.fields.insert(0, idField);
      ctx.shimmed['id'] = true;
    }

    DartType dateTime;
    for (var key in ['createdAt', 'updatedAt']) {
      if (!fieldNames.contains(key)) {
        if (dateTime == null) {
          var coreLib =
              await resolver.libraries.singleWhere((lib) => lib.isDartCore);
          var dt = coreLib.getType('DateTime');
          dateTime = dt.type;
        }

        var field = new ShimFieldImpl(key, dateTime);
        ctx.aliases[key] = new ReCase(key).snakeCase;
        ctx.fields.add(field);
        ctx.shimmed[key] = true;
      }
    }
  }

  // Get constructor params, if any
  ctx.constructorParameters.addAll(clazz.unnamedConstructor.parameters);

  return ctx;
}

/// A manually-instantiated [FieldElement].
class ShimFieldImpl extends FieldElementImpl {
  @override
  final DartType type;

  ShimFieldImpl(String name, this.type) : super(name, -1);
}
