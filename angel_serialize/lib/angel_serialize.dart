export 'dart:convert' show json, Codec, Converter;
export 'package:angel_model/angel_model.dart';
export 'package:collection/collection.dart';
export 'package:meta/meta.dart' show required, Required;
export 'package:quiver_hashcode/hashcode.dart' show hashObjects;

/// Excludes a field from being excluded.
class Exclude extends SerializableField {
  const Exclude({bool canDeserialize = false, bool canSerialize = false})
      : super(
            exclude: true,
            canDeserialize: canDeserialize,
            canSerialize: canSerialize);
}

/// No longer necessary, as this is the default.
@deprecated
const SerializableField nullable = SerializableField(isNullable: true);

/// Marks a field as not accepting `null` values.
const SerializableField notNull = SerializableField(isNullable: false);

const Exclude exclude = Exclude();

/// Shorthand for [SerializableField].
class DefaultsTo extends SerializableField {
  const DefaultsTo(value) : super(defaultValue: value);
}

/// Shorthand for [SerializableField].
class HasAlias extends SerializableField {
  const HasAlias(String name) : super(alias: name);
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

  /// An error message to be printed when the provided value is invalid.
  final String errorMessage;

  /// Whether this field can be set to `null`.
  final bool isNullable;

  /// Whether to exclude this field from serialization. Defaults to `false`.
  final bool exclude;

  /// Whether this field can be serialized, if [exclude] is `true`. Defaults to `false`.
  final bool canDeserialize;

  /// Whether this field can be serialized, if [exclude] is `true`. Defaults to `false`.
  final bool canSerialize;

  /// May be used with [serializer] and [deserializer].
  ///
  /// Specifies the [Type] that this field serializes to.
  ///
  /// Ex. If you have a field that serializes to a JSON string,
  /// specify `serializesTo: String`.
  final Type serializesTo;

  const SerializableField(
      {this.alias,
      this.defaultValue,
      this.serializer,
      this.deserializer,
      this.errorMessage,
      this.isNullable = true,
      this.exclude = false,
      this.canDeserialize = false,
      this.canSerialize = false,
      this.serializesTo});
}

/// Marks a class as eligible for serialization.
class Serializable {
  const Serializable(
      {this.serializers = const [Serializers.map, Serializers.json],
      this.autoSnakeCaseNames = true,
      // ignore: deprecated_member_use_from_same_package
      @deprecated this.autoIdAndDateFields = true,
      this.includeAnnotations = const []});

  /// A list of enabled serialization modes.
  ///
  /// See [Serializers].
  final List<int> serializers;

  /// Overrides the setting in `SerializerGenerator`.
  final bool autoSnakeCaseNames;

  /// Overrides the setting in `JsonModelGenerator`.
  @deprecated
  final bool autoIdAndDateFields;

  /// A list of constant members to affix to the generated class.
  final List includeAnnotations;
}

const Serializable serializable = Serializable();

/// Used by `package:angel_serialize_generator` to reliably identify generated models.
class GeneratedSerializable {
  const GeneratedSerializable();
}

const GeneratedSerializable generatedSerializable = GeneratedSerializable();

/// The supported serialization types.
abstract class Serializers {
  /// All supported serialization types.
  static const List<int> all = [map, json, typescript];

  /// Enable `fromMap` and `toMap` methods on the model class.
  static const int map = 0;

  /// Enable a `toJson` method on the model class.
  static const int json = 1;

  /// Generate a TypeScript definition file (`.d.ts`) for use on the client-side.
  static const int typescript = 2;
}

@deprecated
class DefaultValue {
  final value;

  const DefaultValue(this.value);
}

@deprecated

/// Prefer [SerializableField] instead.
class Alias {
  final String name;

  const Alias(this.name);
}
