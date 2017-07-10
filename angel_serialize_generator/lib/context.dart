import 'package:analyzer/dart/element/element.dart';
import 'package:angel_serialize/angel_serialize.dart';

class BuildContext {
  final Map<String, String> aliases = {};
  final Map<String, bool> shimmed = {};
  final String originalClassName, sourceFilename;
  // Todo: We can use analyzer to copy straight from Model class
  final List<FieldElement> fields = [];
  final Serializable annotation;
  String primaryKeyName = 'id';

  BuildContext(this.annotation, {this.originalClassName, this.sourceFilename});

  String get modelClassName => originalClassName.startsWith('_')
      ? originalClassName.substring(1)
      : originalClassName;

  String resolveFieldName(String name) =>
      aliases.containsKey(name) ? aliases[name] : name;
}
