import 'dart:async';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'context.dart';

// ignore: deprecated_member_use
const TypeChecker aliasTypeChecker = const TypeChecker.fromRuntime(Alias);

const TypeChecker dateTimeTypeChecker = const TypeChecker.fromRuntime(DateTime);

// ignore: deprecated_member_use
const TypeChecker excludeTypeChecker = const TypeChecker.fromRuntime(Exclude);

const TypeChecker serializableFieldTypeChecker =
    const TypeChecker.fromRuntime(SerializableField);

const TypeChecker serializableTypeChecker =
    const TypeChecker.fromRuntime(Serializable);

const TypeChecker generatedSerializableTypeChecker =
    const TypeChecker.fromRuntime(GeneratedSerializable);

final Map<String, BuildContext> _cache = {};

/// Create a [BuildContext].
Future<BuildContext> buildContext(
    ClassElement clazz,
    ConstantReader annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
    {bool heedExclude: true}) async {
  var id = clazz.location.components.join('-');
  if (_cache.containsKey(id)) {
    return _cache[id];
  }

  // Check for autoIdAndDateFields, autoSnakeCaseNames
  autoSnakeCaseNames =
      annotation.peek('autoSnakeCaseNames')?.boolValue ?? autoSnakeCaseNames;

  var ctx = new BuildContext(
    annotation,
    clazz,
    originalClassName: clazz.name,
    sourceFilename: p.basename(buildStep.inputId.path),
    autoSnakeCaseNames: autoSnakeCaseNames,
    includeAnnotations:
        annotation.peek('includeAnnotations')?.listValue ?? <DartObject>[],
  );
  var lib = await resolver.libraryFor(buildStep.inputId);
  List<String> fieldNames = [];

  for (var field in clazz.fields) {
    // Skip private fields
    if (field.name.startsWith('_')) {
      continue;
    }

    if (field.getter != null &&
        (field.setter != null || field.getter.isAbstract)) {
      var el = field.setter == null ? field.getter : field;
      fieldNames.add(field.name);

      // Check for @SerializableField
      var fieldAnn = serializableFieldTypeChecker.firstAnnotationOf(el);

      if (fieldAnn != null) {
        var cr = ConstantReader(fieldAnn);
        var sField = SerializableFieldMirror(
          alias: cr.peek('alias')?.stringValue,
          defaultValue: cr.peek('defaultValue')?.objectValue,
          serializer: cr.peek('serializer')?.symbolValue,
          deserializer: cr.peek('deserializer')?.symbolValue,
          errorMessage: cr.peek('errorMessage')?.stringValue,
          isNullable: cr.peek('isNullable')?.boolValue ?? true,
          canDeserialize: cr.peek('canDeserialize')?.boolValue ?? false,
          canSerialize: cr.peek('canSerialize')?.boolValue ?? false,
          exclude: cr.peek('exclude')?.boolValue ?? false,
          serializesTo: cr.peek('serializesTo')?.typeValue,
        );

        ctx.fieldInfo[field.name] = sField;

        if (sField.defaultValue != null) {
          ctx.defaults[field.name] = sField.defaultValue;
        }

        if (sField.alias != null) {
          ctx.aliases[field.name] = sField.alias;
        } else if (autoSnakeCaseNames != false) {
          ctx.aliases[field.name] = new ReCase(field.name).snakeCase;
        }

        if (sField.isNullable == false) {
          var reason = sField.errorMessage ??
              "Missing required field '${ctx.resolveFieldName(field.name)}' on ${ctx.modelClassName}.";
          ctx.requiredFields[field.name] = reason;
        }

        if (sField.exclude) {
          // ignore: deprecated_member_use
          ctx.excluded[field.name] = new Exclude(
            canSerialize: sField.canSerialize,
            canDeserialize: sField.canDeserialize,
          );
        }

        // Apply
      } else {
        // Skip if annotated with @exclude
        var excludeAnnotation = excludeTypeChecker.firstAnnotationOf(el);

        if (excludeAnnotation != null) {
          var cr = new ConstantReader(excludeAnnotation);

          // ignore: deprecated_member_use
          ctx.excluded[field.name] = new Exclude(
            canSerialize: cr.read('canSerialize').boolValue,
            canDeserialize: cr.read('canDeserialize').boolValue,
          );
        }

        // Check for @DefaultValue()
        var defAnn =
            // ignore: deprecated_member_use
            const TypeChecker.fromRuntime(DefaultValue).firstAnnotationOf(el);
        if (defAnn != null) {
          var rev = new ConstantReader(defAnn).revive().positionalArguments[0];
          ctx.defaults[field.name] = rev;
        }

        // Check for alias
        // ignore: deprecated_member_use
        Alias alias;
        var aliasAnn = aliasTypeChecker.firstAnnotationOf(el);

        if (aliasAnn != null) {
          // ignore: deprecated_member_use
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
          log.warning(
              'Using @required on fields (like ${clazz.name}.${field.name}) is now deprecated; use @SerializableField(isNullable: false) instead.');
          var cr = new ConstantReader(required);
          var reason = cr.peek('reason')?.stringValue ??
              "Missing required field '${ctx.resolveFieldName(field.name)}' on ${ctx.modelClassName}.";
          ctx.requiredFields[field.name] = reason;
        }
      }

      ctx.fields.add(field);
    }
  }

  if (const TypeChecker.fromRuntime(Model).isAssignableFromType(clazz.type)) {
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
