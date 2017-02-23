import 'generator.dart';
import 'package:code_builder/code_builder.dart';

class MapServiceGenerator extends ServiceGenerator {
  @override
  bool get createsModel => false;

  const MapServiceGenerator() : super('In-Memory');

  @override
  ExpressionBuilder createInstance(
      MethodBuilder methodBuilder, String name, String lower) {
    return new TypeBuilder('MapService').newInstance([]);
  }
}
