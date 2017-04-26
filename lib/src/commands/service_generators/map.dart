import 'generator.dart';
import 'package:code_builder/code_builder.dart';

class MapServiceGenerator extends ServiceGenerator {
  const MapServiceGenerator() : super('In-Memory');

  @override
  bool get createsModel => false;

  @override
  ExpressionBuilder createInstance(
      MethodBuilder methodBuilder, String name, String lower) {
    return new TypeBuilder('MapService').newInstance([]);
  }
}
