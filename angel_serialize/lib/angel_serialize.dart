/// Excludes a field from being excluded.
class Exclude {
  const Exclude();
}

const Exclude exclude = const Exclude();

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

/// The supported serialization types.
abstract class Serializers {
  /// All supported serialization types.
  static const List<int> all = const [map, json];

  /// Enable `fromMap` and `toMap` methods on the model class.
  static const int map = 0;

  /// Enable a `toJson` method on the model class.
  static const int json = 1;
}

/// Specifies an alias for a field within its JSON representation.
class Alias {
  final String name;

  const Alias(this.name);
}
