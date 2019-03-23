import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:jael/jael.dart' as jael;
import 'package:jael_preprocessor/jael_preprocessor.dart' as jael;
import 'package:jael_web/jael_web.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'util.dart';

var _upper = RegExp(r'^[A-Z]');

Builder jaelComponentBuilder(_) {
  return SharedPartBuilder([JaelComponentGenerator()], 'jael_web_cmp');
}

class JaelComponentGenerator extends GeneratorForAnnotation<Jael> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is ClassElement) {
      // Load the template
      String templateString;
      var inputId = buildStep.inputId;
      var ann = Jael(
        template: annotation.peek('template')?.stringValue,
        templateUrl: annotation.peek('templateUrl')?.stringValue,
        asDsx: annotation.peek('asDsx')?.boolValue ?? false,
      );

      if (ann.template == null && ann.templateUrl == null) {
        throw 'Both `template` and `templateUrl` cannot be null.';
      }

      if (ann.template != null)
        templateString = ann.template;
      else {
        var dir = p.dirname(inputId.path);
        var assetId = AssetId(inputId.package, p.join(dir, ann.templateUrl));
        if (!await buildStep.canRead(assetId)) {
          throw 'Cannot find template "${assetId.uri}"';
        } else {
          templateString = await buildStep.readAsString(assetId);
        }
      }

      var fs = BuildFileSystem(buildStep, inputId.package);
      var errors = <jael.JaelError>[];
      var doc = await jael.parseDocument(templateString,
          sourceUrl: inputId.uri, asDSX: ann.asDsx, onError: errors.add);
      if (errors.isEmpty) {
        doc = await jael.resolve(doc, fs.file(inputId.uri).parent,
            onError: errors.add);
      }

      if (errors.isNotEmpty) {
        errors.forEach(log.severe);
        throw 'Jael processing finished with ${errors.length} error(s).';
      }

      // Generate a _XJaelTemplate mixin class
      var clazz = Class((b) {
        b
          ..abstract = true
          ..name = '_${element.name}JaelTemplate'
          ..implements.add(convertTypeReference(element.supertype));

        // Add fields corresponding to each of the class's fields.
        for (var field in element.fields) {
          b.methods.add(Method((b) {
            b
              ..name = field.name
              ..type = MethodType.getter
              ..returns = convertTypeReference(field.type);
          }));
        }

        // ... And methods too.
        for (var method in element.methods) {
          b.methods.add(Method((b) {
            b
              ..name = method.name
              ..returns = convertTypeReference(method.returnType)
              ..requiredParameters.addAll(method.parameters
                  .where(isRequiredParameter)
                  .map(convertParameter))
              ..optionalParameters.addAll(method.parameters
                  .where(isOptionalParameter)
                  .map(convertParameter));
          }));
        }

        // Add a render() stub
        b.methods.add(Method((b) {
          b
            ..name = 'render'
            ..returns = refer('DomNode')
            ..annotations.add(refer('override'))
            ..body = Block((b) {
              var result = compileElementChild(doc.root);
              b.addExpression(result.returned);
            });
        }));
      });

      return clazz.accept(DartEmitter()).toString();
    } else {
      throw '@Jael() is only supported for classes.';
    }
  }

  Expression compileElementChild(jael.ElementChild child) {
    if (child is jael.TextNode || child is jael.Text) {
      return refer('text').call([literalString(child.span.text)]);
    } else if (child is jael.Interpolation) {
      Expression expr = CodeExpression(Code(child.expression.span.text));
      expr = expr.property('toString').call([]);
      return refer('text').call([expr]);
    } else if (child is jael.Element) {
      // TODO: Handle strict resolution
      var attrs = <String, Expression>{};
      for (var attr in child.attributes) {
        attrs[attr.name] = attr.value == null
            ? literalTrue
            : CodeExpression(Code(attr.value.span.text));
      }

      var tagName = child.tagName.name;
      if (!_upper.hasMatch(tagName)) {
        return refer('h').call([
          literalString(tagName),
          literalMap(attrs),
          literalList(child.children.map(compileElementChild)),
        ]);
      } else {
        // TODO: How to pass children?
        return refer(tagName).newInstance([], attrs);
      }
      // return refer(child.tagName.name).newInstance([]);
    } else {
      throw 'Unsupported: $child';
    }
  }
}
