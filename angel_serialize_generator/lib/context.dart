import 'package:analyzer/dart/element/element.dart';
import 'package:angel_serialize/angel_serialize.dart';

/// A base context for building serializable classes.
class BuildContext {
  /// A map of field names to resolved names from `@Alias()` declarations.
  final Map<String, String> aliases = {};

  /// A map of "synthetic" fields, i.e. `id` and `created_at` injected automatically.
  final Map<String, bool> shimmed = {};

  final String originalClassName, sourceFilename;

  /// The fields declared on the original class.
  final List<FieldElement> fields = [];

  final Serializable annotation;

  /// The name of the field that identifies data of this model type.
  String primaryKeyName = 'id';

  BuildContext(this.annotation, {this.originalClassName, this.sourceFilename});

  /// The name of the generated class.
  String get modelClassName => originalClassName.startsWith('_')
      ? originalClassName.substring(1)
      : originalClassName;

  /// The [FieldElement] pointing to the primary key.
  FieldElement get primaryKeyField =>
      fields.firstWhere((f) => f.name == primaryKeyName);

  /// Get the aliased name (if one is defined) for a field.
  String resolveFieldName(String name) =>
      aliases.containsKey(name) ? aliases[name] : name;
}
