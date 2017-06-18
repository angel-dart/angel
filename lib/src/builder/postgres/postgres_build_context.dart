import 'package:analyzer/dart/element/element.dart';
import '../../annotations.dart';
import '../../migration.dart';
import '../../relations.dart';

class PostgresBuildContext {
  final Map<String, String> aliases = {};
  final Map<String, Column> columnInfo = {};
  final Map<String, IndexType> indices = {};
  final Map<String, Relationship> relationships = {};
  final String originalClassName, tableName, sourceFilename;
  final ORM annotation;
  // Todo: We can use analyzer to copy straight from Model class
  final List<FieldElement> fields = [];
  String primaryKeyName = 'id';

  PostgresBuildContext(this.annotation,
      {this.originalClassName, this.tableName, this.sourceFilename});

  String get modelClassName => originalClassName.startsWith('_')
      ? originalClassName.substring(1)
      : originalClassName;

  String get queryClassName => modelClassName + 'Query';
  String get whereClassName => queryClassName + 'Where';

  String resolveFieldName(String name) =>
      aliases.containsKey(name) ? aliases[name] : name;
}
