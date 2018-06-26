import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dsx/dsx.dart';
import 'package:jael/jael.dart' as jael;
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class DSXGenerator extends GeneratorForAnnotation<DSX> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    var asset = buildStep.inputId;
    var template = annotation.peek('template')?.stringValue,
        templateUrl = annotation.peek('templateUrl')?.stringValue;
    Library lib;

    if (template != null) {
      lib = generateForDocument(
          jael.parseDocument(template, sourceUrl: asset.uri), element);
    } else if (templateUrl != null) {
      var id =
          new AssetId(asset.package, p.relative(templateUrl, from: asset.path));
      lib = generateForDocument(
          jael.parseDocument(await buildStep.readAsString(id),
              sourceUrl: asset.uri),
          element);
    } else {
      throw '@DSX() cannot be called without a `template` or `templateUrl`.';
    }

    return lib.accept(new DartEmitter()).toString();
  }

  Library generateForDocument(jael.Document document, ClassElement clazz) {}
}
