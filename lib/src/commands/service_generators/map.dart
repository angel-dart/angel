import 'generator.dart';
import 'package:code_builder/code_builder.dart';

class MapServiceGenerator extends ServiceGenerator {
  const MapServiceGenerator() : super('In-Memory');

  @override
  bool get createsModel => false;

  @override
  Expression createInstance(LibraryBuilder library, MethodBuilder methodBuilder,
      String name, String lower) {
    return refer('MapService').newInstance([]);
  }
}
