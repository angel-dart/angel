import 'package:code_builder/code_builder.dart';
import 'generator.dart';

class CustomServiceGenerator extends ServiceGenerator {
  @override
  bool get createsModel => false;

  @override
  bool get createsValidator => false;

  const CustomServiceGenerator() : super('Custom');

  @override
  void applyToLibrary(LibraryBuilder library, String name, String lower) {
    library.body.add(new Class((clazz) {
      clazz
        ..name = '${name}Service'
        ..extend = refer('Service');
    }));
  }

  @override
  Expression createInstance(LibraryBuilder library, MethodBuilder methodBuilder,
      String name, String lower) {
    return refer('${name}Service').newInstance([]);
  }
}
