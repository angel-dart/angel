import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder ormBuilder(_) {
  return new LibraryBuilder(new OrmGenerator(),
      generatedExtension: '.orm.g.dart');
}

class OrmGenerator extends GeneratorForAnnotation<ORM> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is ClassElement) {
    } else {
      throw 'The @Orm() annotation can only be applied to classes.';
    }
  }
}
