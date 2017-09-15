import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'context.dart';

const TypeChecker aliasTypeChecker = const TypeChecker.fromRuntime(Alias);

const TypeChecker excludeTypeChecker = const TypeChecker.fromRuntime(Exclude);

const TypeChecker serializableTypeChecker =
const TypeChecker.fromRuntime(Serializable);

// TODO: Should add id, createdAt, updatedAt...
BuildContext buildContext(
    ClassElement clazz,
    Serializable annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
    bool autoIdAndDateFields,
    {bool heedExclude: true}) {
  var ctx = new BuildContext(annotation,
      originalClassName: clazz.name,
      sourceFilename: p.basename(buildStep.inputId.path));
  var lib = resolver.getLibrary(buildStep.inputId);
  List<String> fieldNames = [];

  for (var field in clazz.fields) {
    if (field.getter != null && field.setter != null) {
      fieldNames.add(field.name);
      // Skip if annotated with @exclude
      var excludeAnnotation = excludeTypeChecker.firstAnnotationOf(field);
      if (excludeAnnotation != null) continue;
      // Check for alias
      Alias alias;
      var aliasAnn = aliasTypeChecker.firstAnnotationOf(field);

      if (aliasAnn != null) {
        alias = new Alias(aliasAnn.getField('name').toStringValue());
      }

      if (alias?.name?.isNotEmpty == true) {
        ctx.aliases[field.name] = alias.name;
      } else if (autoSnakeCaseNames != false) {
        ctx.aliases[field.name] = new ReCase(field.name).snakeCase;
      }

      ctx.fields.add(field);
    }
  }

  if (autoIdAndDateFields != false) {
    if (!fieldNames.contains('id')) {
      var idField = new _ShimField('id', lib.context.typeProvider.stringType);
      ctx.fields.insert(0, idField);
      ctx.shimmed['id'] = true;
    }

    DartType dateTime;
    ['createdAt', 'updatedAt'].forEach((key) {
      if (!fieldNames.contains(key)) {
        if (dateTime == null) {
          var coreLib = resolver.libraries.singleWhere((lib) => lib.isDartCore);
          var dt = coreLib.getType('DateTime');
          dateTime = dt.type;
        }

        var field = new _ShimField(key, dateTime);
        ctx.aliases[key] = new ReCase(key).snakeCase;
        ctx.fields.add(field);
        ctx.shimmed[key] = true;
      }
    });
  }

  return ctx;
}

class _ShimField extends FieldElementImpl {
  @override
  final DartType type;
  _ShimField(String name, this.type) : super(name, -1);
}
