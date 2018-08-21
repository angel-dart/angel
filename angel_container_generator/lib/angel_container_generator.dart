import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/generator.dart';

Builder angelContainerBuilder(BuilderOptions builderOptions) {
  return new PartBuilder([new AngelContainerGenerator()], '.reflector.g.dart');
}
