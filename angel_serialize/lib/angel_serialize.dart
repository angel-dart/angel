export 'package:quiver_hashcode/hashcode.dart' show hashObjects;

/// Excludes a field from being excluded.
class Exclude {
  final bool canSerialize;

  final bool canDeserialize;

  const Exclude({this.canDeserialize: false, this.canSerialize: false});
}

const Exclude exclude = const Exclude();

@deprecated

/// Prefer [SerializableField] instead.
class DefaultValue {
  final value;

  const DefaultValue(this.value);
}

/// Attaches options to a field.
class SerializableField {
  /// An alternative name for this field.
  final String alias;

  /// A default for this field.
  final defaultValue;

  /// A custom serializer for this field.
  final Symbol serializer;

  /// A custom serializer for this field.
  final Symbol deserializer;

  /// A list of constant members to affix to the generated class.
  final List includeAnnotations;

  SerializableField(
      {this.alias,
      this.defaultValue,
      this.serializer,
      this.deserializer,
      this.includeAnnotations: const []});
}

/// Marks a class as eligible for serialization.
class Serializable {
  const Serializable(
      {this.serializers: const [Serializers.map, Serializers.json],
      this.autoSnakeCaseNames: true,
      this.autoIdAndDateFields: true});

  /// A list of enabled serialization modes.
  ///
  /// See [Serializers].
  final List<int> serializers;

  /// Overrides the setting in `SerializerGenerator`.
  final bool autoSnakeCaseNames;

  /// Overrides the setting in `JsonModelGenerator`.
  final bool autoIdAndDateFields;
}

const Serializable serializable = const Serializable();

/// Used by `package:angel_serialize_generator` to reliably identify generated models.
class GeneratedSerializable {
  const GeneratedSerializable();
}

const GeneratedSerializable generatedSerializable =
    const GeneratedSerializable();

/// The supported serialization types.
abstract class Serializers {
  /// All supported serialization types.
  static const List<int> all = const [map, json, typescript];

  /// Enable `fromMap` and `toMap` methods on the model class.
  static const int map = 0;

  /// Enable a `toJson` method on the model class.
  static const int json = 1;

  /// Generate a TypeScript definition file (`.d.ts`) for use on the client-side.
  static const int typescript = 2;
}

@deprecated

/// Prefer [SerializableField] instead.
class Alias {
  final String name;

  const Alias(this.name);
}
