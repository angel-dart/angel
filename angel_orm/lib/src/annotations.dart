const ORM orm = const ORM();

class ORM {
  /// The path to an Angel service that queries objects of the
  /// annotated type at runtime.
  ///
  /// Ex. `api/users`, etc.
  final String servicePath;
  const ORM([this.servicePath]);
}

/// Specifies that the ORM should build a join builder
/// that combines the results of queries on two services.
class Join {
  /// The [Model] type to join against.
  final Type type;

  /// The path to an Angel service that queries objects of the
  /// [type] being joined against, at runtime.
  ///
  /// Ex. `api/users`, etc.
  final String servicePath;

  /// The type of join this is.
  final JoinType joinType;

  const Join(this.type, this.servicePath, [this.joinType = JoinType.join]);
}

/// The various types of [Join].
enum JoinType { join, left, right, full, self }
