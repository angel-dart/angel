/// Excludes a field from being excluded.
class Exclude {
  const Exclude();
}

const Exclude exclude = const Exclude();

/// Marks a class as eligible for serialization.
class Serializable {
  const Serializable();
}

const Serializable serializable = const Serializable();

/// Specifies an alias for a field within its JSON representation.
class Alias {
  final String name;
  const Alias(this.name);
}