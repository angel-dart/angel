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
    var clazz = new ClassBuilder('${name}Service', asExtends: new TypeBuilder('Service'));
    library.addMember(clazz);
  }

  @override
  ExpressionBuilder createInstance(
      MethodBuilder methodBuilder, String name, String lower) {
    return new TypeBuilder('${name}Service').newInstance([]);
  }
}
